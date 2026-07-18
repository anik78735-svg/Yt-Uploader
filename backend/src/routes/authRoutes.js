const express = require('express');
const router = express.Router();
const User = require('../models/User');

router.post('/register', async (req, res, next) => {
  try {
    const { googleId, email, username, refreshToken, youtubeChannelName } = req.body;
    if (!googleId || !email) {
      return res.status(400).json({ success: false, error: 'googleId and email are required' });
    }

    let user = await User.findOne({ googleId });
    if (!user) {
      user = await User.create({
        googleId,
        email,
        username: username || `user_${Date.now()}`,
        encryptedRefreshToken: refreshToken || '',
        youtubeChannelName: youtubeChannelName || '',
        role: email === 'youradminemail@gmail.com' ? 'ADMIN' : 'USER',
      });
    } else {
      user.email = email;
      user.username = username || user.username;
      user.encryptedRefreshToken = refreshToken || user.encryptedRefreshToken;
      user.youtubeChannelName = youtubeChannelName || user.youtubeChannelName;
      await user.save();
    }

    res.json({ success: true, user });
  } catch (error) {
    next(error);
  }
});

router.post('/logout', async (req, res, next) => {
  try {
    const { userId } = req.body;
    if (!userId) return res.status(400).json({ success: false, error: 'userId required' });
    await User.findByIdAndUpdate(userId, { isSessionActive: false });
    res.json({ success: true });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
