const express = require('express');
const router = express.Router();
const ScheduledVideo = require('../models/ScheduledVideo');
const { requireAuth } = require('../middleware/auth');

router.use(requireAuth);

router.get('/', async (req, res, next) => {
  try {
    const schedules = await ScheduledVideo.find({ userId: req.user.userId }).sort({ scheduledAt: 1 });
    res.json({ success: true, schedules });
  } catch (error) {
    next(error);
  }
});

router.post('/', async (req, res, next) => {
  try {
    const schedule = await ScheduledVideo.create({ ...req.body, userId: req.user.userId });
    res.json({ success: true, schedule });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
