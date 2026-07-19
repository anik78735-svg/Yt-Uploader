const express = require('express');
const jwt = require('jsonwebtoken');
const { google } = require('googleapis');
const router = express.Router();
const User = require('../models/User');
const googleAuthClient = require('../config/googleAuth');
const { youtubeOAuthClient } = require('../config/youtubeAuth');
const { encryptToken } = require('../utils/crypto');
const { requireAuth } = require('../middleware/auth');

function sanitizeUser(user) {
  const plainUser = user.toObject ? user.toObject() : user;
  delete plainUser.encryptedRefreshToken;
  return plainUser;
}

async function handleGoogleLogin(req, res, next) {
  try {
    const { idToken, username } = req.body;
    if (!idToken) {
      return res.status(400).json({ success: false, error: 'idToken is required' });
    }

    const ticket = await googleAuthClient.verifyIdToken({
      idToken,
      audience: process.env.GOOGLE_CLIENT_ID,
    });

    const payload = ticket.getPayload();
    if (!payload || !payload.email || !payload.sub) {
      return res.status(401).json({ success: false, error: 'Google authentication failed' });
    }

    const verifiedGoogleId = payload.sub;
    const verifiedEmail = (payload.email || '').toLowerCase();
    const verifiedName = payload.name || payload.given_name || verifiedEmail;
    const customUsernameProvided = typeof username === 'string' && username.trim().length > 0;

    let user = await User.findOne({ googleId: verifiedGoogleId });
    if (!user) {
      user = await User.findOne({ email: verifiedEmail });
    }

    const isNewUser = !user;

    if (!user) {
      user = await User.create({
        googleId: verifiedGoogleId,
        email: verifiedEmail,
        username: customUsernameProvided ? username.trim() : `user_${Date.now()}`,
        hasCustomUsername: customUsernameProvided,
        role: verifiedEmail === 'anik78735@gmail.com' ? 'ADMIN' : 'USER',
      });
    } else {
      user.googleId = verifiedGoogleId;
      user.email = verifiedEmail;
      if (customUsernameProvided) {
        user.username = username.trim();
        user.hasCustomUsername = true;
      } else if (!user.username) {
        user.username = verifiedName;
      }
      user.isSessionActive = true;
      await user.save();
    }

    const token = jwt.sign({ userId: user._id, role: user.role }, process.env.JWT_SECRET, { expiresIn: '7d' });

    res.json({
      success: true,
      token,
      user: sanitizeUser(user),
      isNewUser,
    });
  } catch (error) {
    next(error);
  }
}

router.post('/google-login', handleGoogleLogin);
router.post('/register', handleGoogleLogin);

router.get('/youtube-auth-url', requireAuth, async (req, res, next) => {
  try {
    const authUrl = youtubeOAuthClient.generateAuthUrl({
      access_type: 'offline',
      prompt: 'consent',
      scope: [
        'https://www.googleapis.com/auth/youtube.upload',
        'https://www.googleapis.com/auth/youtube.readonly',
      ],
    });

    res.json({ success: true, url: authUrl });
  } catch (error) {
    next(error);
  }
});

router.get('/youtube-callback', async (req, res) => {
  const { code, error } = req.query;

  let redirectUrl = 'com.tubepilot.app://oauthconnect?error=missing_code';
  if (typeof error === 'string' && error.length > 0) {
    redirectUrl = `com.tubepilot.app://oauthconnect?error=${encodeURIComponent(error)}`;
  } else if (typeof code === 'string' && code.length > 0) {
    redirectUrl = `com.tubepilot.app://oauthconnect?code=${encodeURIComponent(code)}`;
  }

  return res.redirect(302, redirectUrl);
});

router.get('/check-username', async (req, res, next) => {
  try {
    const { username } = req.query;
    if (!username || typeof username !== 'string' || username.trim().length === 0) {
      return res.status(400).json({ success: false, error: 'Username is required' });
    }

    const cleanUsername = username.trim();
    const existingUser = await User.findOne({ username: cleanUsername });
    res.json({ success: true, available: existingUser === null });
  } catch (error) {
    next(error);
  }
});

router.patch('/set-username', requireAuth, async (req, res, next) => {
  try {
    const { username } = req.body;
    if (!username || typeof username !== 'string' || username.trim().length === 0) {
      return res.status(400).json({ success: false, error: 'Username is required' });
    }

    const cleanUsername = username.trim();
    const existingUser = await User.findOne({ username: cleanUsername, _id: { $ne: req.user.userId } });
    if (existingUser) {
      return res.status(409).json({ success: false, error: 'Username already taken' });
    }

    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    user.username = cleanUsername;
    user.hasCustomUsername = true;
    user.isSessionActive = true;
    await user.save();

    res.json({ success: true, user: sanitizeUser(user) });
  } catch (error) {
    next(error);
  }
});

router.post('/youtube-connect', requireAuth, async (req, res, next) => {
  try {
    const { code } = req.body;
    if (!code) {
      return res.status(400).json({ success: false, error: 'Authorization code is required' });
    }

    const { tokens } = await youtubeOAuthClient.getToken(code);
    if (!tokens.refresh_token) {
      return res.status(400).json({ success: false, error: 'YouTube refresh token was not returned' });
    }

    youtubeOAuthClient.setCredentials(tokens);
    const youtube = google.youtube({ version: 'v3', auth: youtubeOAuthClient });
    const response = await youtube.channels.list({ part: ['snippet'], mine: true });
    const channelName = response.data.items?.[0]?.snippet?.title || '';

    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    user.encryptedRefreshToken = encryptToken(tokens.refresh_token);
    user.youtubeChannelName = channelName;
    user.isSessionActive = true;
    await user.save();

    res.json({ success: true, user: sanitizeUser(user) });
  } catch (error) {
    next(error);
  }
});

router.post('/logout', requireAuth, async (req, res, next) => {
  try {
    await User.findByIdAndUpdate(req.user.userId, { isSessionActive: false });
    res.json({ success: true });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
