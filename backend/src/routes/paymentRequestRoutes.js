const express = require('express');
const router = express.Router();
const crypto = require('crypto');
const PaymentRequest = require('../models/PaymentRequest');
const PaymentSettings = require('../models/PaymentSettings');
const Wallet = require('../models/Wallet');
const WalletHistory = require('../models/WalletHistory');
const User = require('../models/User');
const { requireAuth, requireAdmin } = require('../middleware/auth');

function generateSecureToken() {
  return crypto.randomBytes(32).toString('hex');
}

async function getOrCreateWallet(userId) {
  let wallet = await Wallet.findOne({ userId });
  if (!wallet) {
    wallet = await Wallet.create({ userId });
  }
  return wallet;
}

router.post('/request', requireAuth, async (req, res, next) => {
  try {
    const { packageId } = req.body;

    const settings = await PaymentSettings.findOne();
    if (!settings) {
      return res.status(400).json({ success: false, error: 'Payment settings not configured' });
    }

    const pkg = settings.diamondPackages.find((entry) => entry.packageId === packageId && entry.enabled);
    if (!pkg) {
      return res.status(404).json({ success: false, error: 'Package not available' });
    }

    const existingRequest = await PaymentRequest.findOne({
      userId: req.user.userId,
      packageId,
      status: { $in: ['PENDING', 'APPROVED'] },
    }).sort({ generatedAt: -1 });

    if (existingRequest) {
      return res.json({
        success: true,
        paymentRequest: existingRequest,
        paymentUrl: `/pay/${existingRequest.paymentId}?token=${existingRequest.secureToken}`,
        duplicate: true,
      });
    }

    const paymentId = `PAY_${Date.now()}_${Math.random().toString(36).substr(2, 9).toUpperCase()}`;
    const secureToken = generateSecureToken();

    const paymentRequest = await PaymentRequest.create({
      userId: req.user.userId,
      paymentId,
      packageId,
      diamonds: pkg.diamonds,
      amount: pkg.price,
      secureToken,
      ipAddress: req.ip,
      userAgent: req.get('user-agent'),
    });

    const wallet = await getOrCreateWallet(req.user.userId);
    wallet.pendingRequests += 1;
    await wallet.save();

    res.json({
      success: true,
      paymentRequest,
      paymentUrl: `/pay/${paymentId}?token=${secureToken}`,
    });
  } catch (error) {
    next(error);
  }
});

router.get('/request/:paymentId', async (req, res, next) => {
  try {
    const { paymentId } = req.params;
    const { token } = req.query;

    const paymentRequest = await PaymentRequest.findOne({ paymentId });
    if (!paymentRequest) {
      return res.status(404).json({ success: false, error: 'Payment request not found' });
    }

    if (!token || token !== paymentRequest.secureToken) {
      return res.status(403).json({ success: false, error: 'Invalid or expired payment link' });
    }

    if (paymentRequest.status === 'APPROVED') {
      return res.status(400).json({ success: false, error: 'Payment already processed' });
    }

    const expiryTime = 24 * 60 * 60 * 1000;
    if (Date.now() - paymentRequest.generatedAt > expiryTime) {
      paymentRequest.status = 'EXPIRED';
      await paymentRequest.save();
      return res.status(400).json({ success: false, error: 'Payment link expired' });
    }

    const settings = await PaymentSettings.findOne();
    const user = await User.findById(paymentRequest.userId);

    res.json({
      success: true,
      paymentRequest,
      paymentSettings: {
        merchantName: settings?.merchantName,
        upiId: settings?.upiId,
        qrImageUrl: settings?.qrImageUrl,
        paymentInstructions: settings?.paymentInstructions,
      },
      userInfo: {
        username: user?.username,
        email: user?.email,
      },
    });
  } catch (error) {
    next(error);
  }
});

router.post('/request/:paymentId/complete', async (req, res, next) => {
  try {
    const { paymentId } = req.params;
    const { token } = req.body;

    const paymentRequest = await PaymentRequest.findOne({ paymentId });
    if (!paymentRequest) {
      return res.status(404).json({ success: false, error: 'Payment request not found' });
    }

    if (!token || token !== paymentRequest.secureToken) {
      return res.status(403).json({ success: false, error: 'Invalid payment link' });
    }

    if (paymentRequest.status !== 'PENDING') {
      return res.status(400).json({ success: false, error: 'Payment request already processed' });
    }

    res.json({
      success: true,
      message: 'Payment completed. Admin will verify your payment within 24 hours.',
      paymentRequest,
    });
  } catch (error) {
    next(error);
  }
});

router.get('/admin/pending', requireAuth, requireAdmin, async (req, res, next) => {
  try {
    const { limit = 50, skip = 0, search } = req.query;

    let query = { status: 'PENDING' };

    if (search) {
      const user = await User.findOne({
        $or: [
          { username: { $regex: search, $options: 'i' } },
          { email: { $regex: search, $options: 'i' } },
        ],
      });
      if (user) {
        query.userId = user._id;
      }
    }

    const payments = await PaymentRequest.find(query)
      .populate('userId', 'username email youtubeChannelName')
      .sort({ generatedAt: -1 })
      .limit(parseInt(limit))
      .skip(parseInt(skip));

    const total = await PaymentRequest.countDocuments(query);

    res.json({
      success: true,
      payments,
      total,
      hasMore: (skip + payments.length) < total,
    });
  } catch (error) {
    next(error);
  }
});

router.post('/admin/approve', requireAuth, requireAdmin, async (req, res, next) => {
  try {
    const { paymentId, notes } = req.body;

    const paymentRequest = await PaymentRequest.findOne({ paymentId });
    if (!paymentRequest) {
      return res.status(404).json({ success: false, error: 'Payment request not found' });
    }

    if (paymentRequest.status !== 'PENDING') {
      return res.status(400).json({ success: false, error: 'Payment already processed' });
    }

    paymentRequest.status = 'APPROVED';
    paymentRequest.approvedAt = new Date();
    paymentRequest.approvedByAdmin = req.user.userId;
    paymentRequest.notes = notes || '';
    await paymentRequest.save();

    const user = await User.findById(paymentRequest.userId);
    let wallet = await getOrCreateWallet(paymentRequest.userId);

    const beforeBalance = wallet.currentDiamonds;
    wallet.currentDiamonds += paymentRequest.diamonds;
    wallet.lifetimeDiamondsPurchased += paymentRequest.diamonds;
    wallet.lastPurchaseDate = new Date();
    wallet.totalSpent += paymentRequest.amount;
    wallet.pendingRequests -= 1;
    await wallet.save();

    await WalletHistory.create({
      userId: paymentRequest.userId,
      walletId: wallet._id,
      transactionType: 'PURCHASE',
      diamondAmount: paymentRequest.diamonds,
      beforeBalance,
      afterBalance: wallet.currentDiamonds,
      description: `Diamonds purchased - Package: ${paymentRequest.packageId}`,
      relatedPaymentId: paymentRequest._id,
      reference: paymentRequest.paymentId,
    });

    user.diamondBalance = wallet.currentDiamonds;
    await user.save();

    res.json({ success: true, paymentRequest, wallet });
  } catch (error) {
    next(error);
  }
});

router.post('/admin/reject', requireAuth, requireAdmin, async (req, res, next) => {
  try {
    const { paymentId, rejectionReason } = req.body;

    const paymentRequest = await PaymentRequest.findOne({ paymentId });
    if (!paymentRequest) {
      return res.status(404).json({ success: false, error: 'Payment request not found' });
    }

    if (paymentRequest.status !== 'PENDING') {
      return res.status(400).json({ success: false, error: 'Payment already processed' });
    }

    paymentRequest.status = 'REJECTED';
    paymentRequest.rejectedAt = new Date();
    paymentRequest.rejectionReason = rejectionReason || 'No reason provided';
    await paymentRequest.save();

    const wallet = await getOrCreateWallet(paymentRequest.userId);
    wallet.pendingRequests -= 1;
    wallet.rejectedRequests += 1;
    await wallet.save();

    res.json({ success: true, paymentRequest });
  } catch (error) {
    next(error);
  }
});

router.get('/admin/history', requireAuth, requireAdmin, async (req, res, next) => {
  try {
    const { limit = 50, skip = 0, status, search } = req.query;

    let query = {};

    if (status) {
      query.status = status;
    }

    if (search) {
      query.$or = [{ paymentId: { $regex: search, $options: 'i' } }];
    }

    const payments = await PaymentRequest.find(query)
      .populate('userId', 'username email')
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .skip(parseInt(skip));

    const total = await PaymentRequest.countDocuments(query);

    res.json({ success: true, payments, total, hasMore: (skip + payments.length) < total });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
