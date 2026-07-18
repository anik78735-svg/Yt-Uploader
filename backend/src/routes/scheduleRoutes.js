const express = require('express');
const router = express.Router();
const ScheduledVideo = require('../models/ScheduledVideo');

router.get('/', async (req, res, next) => {
  try {
    const schedules = await ScheduledVideo.find().sort({ scheduledAt: 1 });
    res.json({ success: true, schedules });
  } catch (error) {
    next(error);
  }
});

router.post('/', async (req, res, next) => {
  try {
    const schedule = await ScheduledVideo.create(req.body);
    res.json({ success: true, schedule });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
