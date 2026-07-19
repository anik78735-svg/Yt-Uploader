const express = require('express');
const multer = require('multer');
const router = express.Router();
const ScheduledVideo = require('../models/ScheduledVideo');
const User = require('../models/User');
const Wallet = require('../models/Wallet');
const WalletHistory = require('../models/WalletHistory');
const { requireAuth } = require('../middleware/auth');
const { uploadVideo } = require('../services/storageService');

const upload = multer({ storage: multer.memoryStorage() });

router.use(requireAuth);

router.post('/chunk', upload.single('video'), async (req, res, next) => {
  try {
    const { title, description, tags, scheduledAt } = req.body;
    const file = req.file;

    if (!file) return res.status(400).json({ success: false, error: 'Video file required' });

    const user = await User.findById(req.user.userId);
    if (!user) return res.status(404).json({ success: false, error: 'User not found' });

    const deductionAmount = 10;
    if (user.diamondBalance < deductionAmount) {
      return res.status(402).json({ success: false, error: 'Insufficient diamonds' });
    }

    const uploadResult = await uploadVideo(file.buffer, file.originalname || 'video.mp4');

    let wallet = await Wallet.findOne({ userId: req.user.userId });
    if (!wallet) {
      wallet = await Wallet.create({
        userId: req.user.userId,
        currentDiamonds: user.diamondBalance,
      });
    }

    if (wallet.currentDiamonds < deductionAmount) {
      return res.status(402).json({ success: false, error: 'Insufficient diamonds' });
    }

    const beforeBalance = wallet.currentDiamonds;
    wallet.currentDiamonds -= deductionAmount;
    wallet.lifetimeDiamondsUsed += deductionAmount;
    await wallet.save();

    await WalletHistory.create({
      userId: req.user.userId,
      walletId: wallet._id,
      transactionType: 'DEBIT',
      diamondAmount: deductionAmount,
      beforeBalance,
      afterBalance: wallet.currentDiamonds,
      description: title ? `Upload scheduled: ${title}` : 'Diamonds used for upload',
      reference: 'upload_chunk',
    });

    user.diamondBalance = wallet.currentDiamonds;
    await user.save();

    const scheduledVideo = await ScheduledVideo.create({
      userId: req.user.userId,
      title,
      description,
      tags: tags ? tags.split(',') : [],
      scheduledAt: new Date(scheduledAt),
      status: 'PENDING',
      storageProvider: uploadResult.provider,
      remoteFileId: uploadResult.remoteFileId,
    });

    res.json({ success: true, scheduledVideo, provider: uploadResult.provider, url: uploadResult.url, diamondBalance: user.diamondBalance });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
