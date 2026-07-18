const mongoose = require('mongoose');

const ScheduledVideoSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  title: { type: String, required: true },
  description: { type: String, default: '' },
  tags: [{ type: String }],
  scheduledAt: { type: Date, required: true },
  status: { type: String, enum: ['PENDING', 'UPLOADING', 'SUCCESS', 'FAILED'], default: 'PENDING' },
  storageProvider: { type: String, default: '' },
  remoteFileId: { type: String, default: '' },
}, { timestamps: true });

module.exports = mongoose.model('ScheduledVideo', ScheduledVideoSchema);
