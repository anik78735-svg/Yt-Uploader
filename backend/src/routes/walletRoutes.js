const express = require('express');
const router = express.Router();
const Wallet = require('../models/Wallet');
const WalletHistory = require('../models/WalletHistory');
const User = require('../models/User');
const { requireAuth } = require('../middleware/auth');

router.use(requireAuth);

// Get user wallet
router.get('/', async (req, res, next) => {
  try {
    let wallet = await Wallet.findOne({ userId: req.user.userId });
    
    if (!wallet) {
      wallet = await Wallet.create({ userId: req.user.userId });
    }
    
    res.json({ success: true, wallet });
  } catch (error) {
    next(error);
  }
});

// Get wallet history
router.get('/history', async (req, res, next) => {
  try {
    const { limit = 50, skip = 0 } = req.query;
    
    const history = await WalletHistory.find({ userId: req.user.userId })
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .skip(parseInt(skip));
    
    const total = await WalletHistory.countDocuments({ userId: req.user.userId });
    
    res.json({ success: true, history, total, hasMore: (skip + history.length) < total });
  } catch (error) {
    next(error);
  }
});

// Get purchase history
router.get('/purchases', async (req, res, next) => {
  try {
    const { limit = 20, skip = 0 } = req.query;
    
    const purchases = await WalletHistory.find({
      userId: req.user.userId,
      transactionType: { $in: ['PURCHASE', 'CREDIT'] }
    })
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .skip(parseInt(skip));
    
    const total = await WalletHistory.countDocuments({
      userId: req.user.userId,
      transactionType: { $in: ['PURCHASE', 'CREDIT'] }
    });
    
    res.json({ success: true, purchases, total, hasMore: (skip + purchases.length) < total });
  } catch (error) {
    next(error);
  }
});

// Get usage history (debit transactions)
router.get('/usage', async (req, res, next) => {
  try {
    const { limit = 20, skip = 0 } = req.query;
    
    const usage = await WalletHistory.find({
      userId: req.user.userId,
      transactionType: 'DEBIT'
    })
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .skip(parseInt(skip));
    
    const total = await WalletHistory.countDocuments({
      userId: req.user.userId,
      transactionType: 'DEBIT'
    });
    
    res.json({ success: true, usage, total, hasMore: (skip + usage.length) < total });
  } catch (error) {
    next(error);
  }
});

// Get pending requests
router.get('/pending-requests', async (req, res, next) => {
  try {
    const wallet = await Wallet.findOne({ userId: req.user.userId });
    
    if (!wallet) {
      return res.json({ success: true, pendingCount: 0 });
    }
    
    res.json({ success: true, pendingCount: wallet.pendingRequests });
  } catch (error) {
    next(error);
  }
});

// Add diamonds to wallet (admin only - used internally after payment approval)
router.post('/add-diamonds', requireAuth, async (req, res, next) => {
  try {
    const { userId, diamonds, description, relatedTransactionId, reference } = req.body;
    
    // Check if requester is admin
    const admin = await User.findById(req.user.userId);
    if (admin.role !== 'ADMIN') {
      return res.status(403).json({ success: false, error: 'Admin access required' });
    }
    
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }
    
    let wallet = await Wallet.findOne({ userId });
    if (!wallet) {
      wallet = await Wallet.create({ userId });
    }
    
    const beforeBalance = wallet.currentDiamonds;
    wallet.currentDiamonds += diamonds;
    wallet.lifetimeDiamondsPurchased += diamonds;
    wallet.lastPurchaseDate = new Date();
    await wallet.save();
    
    // Log history
    await WalletHistory.create({
      userId,
      walletId: wallet._id,
      transactionType: 'CREDIT',
      diamondAmount: diamonds,
      beforeBalance,
      afterBalance: wallet.currentDiamonds,
      description: description || 'Diamonds added to wallet',
      relatedTransactionId,
      reference,
    });
    
    // Update user diamond balance
    user.diamondBalance = wallet.currentDiamonds;
    await user.save();
    
    res.json({ success: true, wallet });
  } catch (error) {
    next(error);
  }
});

// Deduct diamonds (for video uploads, etc)
router.post('/deduct-diamonds', async (req, res, next) => {
  try {
    const { diamonds, description, reference } = req.body;
    
    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }
    
    let wallet = await Wallet.findOne({ userId: req.user.userId });
    if (!wallet) {
      wallet = await Wallet.create({ userId: req.user.userId });
    }
    
    if (wallet.currentDiamonds < diamonds) {
      return res.status(402).json({ success: false, error: 'Insufficient diamonds' });
    }
    
    const beforeBalance = wallet.currentDiamonds;
    wallet.currentDiamonds -= diamonds;
    wallet.lifetimeDiamondsUsed += diamonds;
    await wallet.save();
    
    // Log history
    await WalletHistory.create({
      userId: req.user.userId,
      walletId: wallet._id,
      transactionType: 'DEBIT',
      diamondAmount: diamonds,
      beforeBalance,
      afterBalance: wallet.currentDiamonds,
      description: description || 'Diamonds used',
      reference,
    });
    
    // Update user diamond balance
    user.diamondBalance = wallet.currentDiamonds;
    await user.save();
    
    res.json({ success: true, wallet });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
