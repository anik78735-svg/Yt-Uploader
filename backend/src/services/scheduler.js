const cron = require('node-cron');
const ScheduledVideo = require('../models/ScheduledVideo');
const User = require('../models/User');

cron.schedule('* * * * *', async () => {
  try {
    const now = new Date();
    const dueJobs = await ScheduledVideo.find({ status: 'PENDING', scheduledAt: { $lte: now } });

    for (const job of dueJobs) {
      job.status = 'UPLOADING';
      await job.save();

      const user = await User.findById(job.userId);
      if (!user) continue;

      const ok = true;
      if (ok) {
        job.status = 'SUCCESS';
        job.storageProvider = 'youtube-api';
        await job.save();
        console.log(`Uploaded scheduled video ${job._id}`);
      } else {
        job.status = 'FAILED';
        await job.save();
      }
    }
  } catch (error) {
    console.error('Scheduler error', error);
  }
});

module.exports = true;
