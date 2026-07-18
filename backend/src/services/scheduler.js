const cron = require('node-cron');
const ScheduledVideo = require('../models/ScheduledVideo');
const User = require('../models/User');
const { getYoutubeClientForUser } = require('../config/youtubeAuth');
const { deleteVideo, downloadVideo } = require('./storageService');

async function processJob(job) {
  try {
    const user = await User.findById(job.userId);
    if (!user) {
      job.status = 'FAILED';
      job.errorMessage = 'User not found';
      await job.save();
      return;
    }

    if (!user.encryptedRefreshToken) {
      job.status = 'FAILED';
      job.errorMessage = 'YouTube authorization not configured';
      await job.save();
      return;
    }

    job.status = 'UPLOADING';
    await job.save();

    const youtube = getYoutubeClientForUser(user);
    const stream = await downloadVideo(job.storageProvider, job.remoteFileId);

    if (!stream) {
      throw new Error('No storage stream available for upload');
    }

    const response = await youtube.videos.insert({
      part: ['snippet', 'status'],
      media: {
        body: stream,
      },
      requestBody: {
        snippet: {
          title: job.title,
          description: job.description || '',
          tags: job.tags || [],
        },
        status: { privacyStatus: 'private' },
      },
    });

    job.status = 'SUCCESS';
    job.youtubeVideoId = response.data.id;
    job.storageProvider = job.storageProvider || 'unknown';
    await job.save();

    if (job.storageProvider && job.remoteFileId) {
      await deleteVideo(job.storageProvider, job.remoteFileId);
    }
  } catch (error) {
    job.status = 'FAILED';
    job.errorMessage = error.message || 'Upload failed';
    await job.save();
  }
}

cron.schedule('* * * * *', async () => {
  try {
    const now = new Date();
    const dueJobs = await ScheduledVideo.find({ status: 'PENDING', scheduledAt: { $lte: now } });

    for (const job of dueJobs) {
      await processJob(job);
    }
  } catch (error) {
    console.error('Scheduler error', error);
  }
});

module.exports = true;
