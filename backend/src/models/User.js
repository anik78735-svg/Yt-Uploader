const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
  googleId: { type: String, required: false, unique: true, sparse: true, index: true },
  email: { type: String, required: true, unique: true, index: true },
  username: { type: String, unique: true, sparse: true, index: true },
  passwordHash: { type: String, default: null },
  authProviders: { type: [String], default: [] },
  hasCustomUsername: { type: Boolean, default: false },
  youtubeChannelName: { type: String, default: '' },
  encryptedRefreshToken: { type: String, default: '' },
  diamondBalance: { type: Number, default: 0 },
  role: { type: String, enum: ['USER', 'ADMIN'], default: 'USER' },
  isSessionActive: { type: Boolean, default: true },
}, { timestamps: true });

module.exports = mongoose.model('User', UserSchema);
