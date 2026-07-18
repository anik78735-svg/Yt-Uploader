const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Transaction = require('../models/Transaction');

router.post('/create', async (req, res, next) => {
  try {
    const { userId, username, amount } = req.body;
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ success: false, error: 'User not found' });

    const transaction = await Transaction.create({
      userId,
      username: username || user.username,
      amount: amount || 99,
      diamondsCredited: 100,
      status: 'PENDING',
    });

    res.json({ success: true, transaction });
  } catch (error) {
    next(error);
  }
});

router.post('/approve', async (req, res, next) => {
  try {
    const { transactionId } = req.body;
    const tx = await Transaction.findById(transactionId);
    if (!tx) return res.status(404).json({ success: false, error: 'Transaction not found' });

    tx.status = 'APPROVED';
    await tx.save();

    await User.findByIdAndUpdate(tx.userId, { $inc: { diamondBalance: tx.diamondsCredited } });

    res.json({ success: true, transaction: tx });
  } catch (error) {
    next(error);
  }
});

router.post('/reject', async (req, res, next) => {
  try {
    const { transactionId } = req.body;
    const tx = await Transaction.findById(transactionId);
    if (!tx) return res.status(404).json({ success: false, error: 'Transaction not found' });

    tx.status = 'REJECTED';
    await tx.save();

    res.json({ success: true, transaction: tx });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
