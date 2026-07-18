const express = require('express');
const multer = require('multer');
const router = express.Router();
const crypto = require('crypto');
const ScheduledVideo = require('../models/ScheduledVideo');

const upload = multer({ storage: multer.memoryStorage() });

router.post('/chunk', upload.single('video'), async (req, res, next) => {
  try {
    const { title, description, tags, scheduledAt, userId } = req.body;
    const file = req.file;

    if (!file) return res.status(400).json({ success: false, error: 'Video file required' });

    const provider = 'cloudinary-primary';
    const scheduledVideo = await ScheduledVideo.create({
      userId,
      title,
      description,
      tags: tags ? tags.split(',') : [],
      scheduledAt: new Date(scheduledAt),
      status: 'PENDING',
      storageProvider: provider,
      remoteFileId: crypto.randomBytes(6).toString('hex'),
    });

    res.json({ success: true, scheduledVideo, provider });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
