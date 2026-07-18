const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Transaction = require('../models/Transaction');

router.get('/users', async (req, res, next) => {
  try {
    const { search } = req.query;
    const query = search ? {
      $or: [
        { username: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
      ],
    } : {};

    const users = await User.find(query).sort({ createdAt: -1 });
    res.json({ success: true, users });
  } catch (error) {
    next(error);
  }
});

router.post('/users/logout', async (req, res, next) => {
  try {
    const { userId } = req.body;
    await User.findByIdAndUpdate(userId, { isSessionActive: false });
    res.json({ success: true });
  } catch (error) {
    next(error);
  }
});

router.get('/transactions/pending', async (req, res, next) => {
  try {
    const transactions = await Transaction.find({ status: 'PENDING' }).sort({ timestamp: -1 });
    res.json({ success: true, transactions });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
