const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Transaction = require('../models/Transaction');
const { requireAuth, requireAdmin } = require('../middleware/auth');

router.use(requireAuth);
router.use(requireAdmin);

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
    await User.findByIdAndUpdate(req.user.userId, { isSessionActive: false });
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
