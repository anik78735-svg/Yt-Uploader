const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
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
  delete plainUser.passwordHash;
  return plainUser;
}

function escapeRegex(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function isValidUsername(username) {
  return /^[a-zA-Z0-9_]{3,20}$/.test(username);
}

async function issueAuthToken(user) {
  return jwt.sign({ userId: user._id, role: user.role }, process.env.JWT_SECRET, { expiresIn: '7d' });
}

router.post('/signup', async (req, res, next) => {
  try {
    const email = (req.body.email || '').trim().toLowerCase();
    const password = req.body.password;
    const username = (req.body.username || '').trim();

    if (!isValidEmail(email)) {
      return res.status(400).json({ success: false, error: 'Please provide a valid email address' });
    }

    if (typeof password !== 'string' || password.length < 8) {
      return res.status(400).json({ success: false, error: 'Password must be at least 8 characters long' });
    }

    if (!isValidUsername(username)) {
      return res.status(400).json({ success: false, error: 'Username must be 3-20 characters using letters, numbers, or underscores' });
    }

    const existingEmailUser = await User.findOne({
      email: { $regex: new RegExp(`^${escapeRegex(email)}$`, 'i') },
    });

    if (existingEmailUser) {
      const existingProviders = Array.isArray(existingEmailUser.authProviders) ? existingEmailUser.authProviders : [];
      if (existingProviders.includes('google') && !existingProviders.includes('password')) {
        return res.status(409).json({
          success: false,
          error: 'This email is already registered with Google Sign-In. Please continue with Google, or add a password from your profile settings.',
        });
      }

      return res.status(409).json({ success: false, error: 'An account with that email already exists' });
    }

    const existingUsernameUser = await User.findOne({
      username: { $regex: new RegExp(`^${escapeRegex(username)}$`, 'i') },
    });

    if (existingUsernameUser) {
      return res.status(409).json({ success: false, error: 'Username already taken' });
    }

    const passwordHash = await bcrypt.hash(password, 12);
    const user = await User.create({
      email,
      username,
      passwordHash,
      hasCustomUsername: true,
      authProviders: ['password'],
      role: email === 'anik78735@gmail.com' ? 'ADMIN' : 'USER',
      isSessionActive: true,
    });

    const token = await issueAuthToken(user);
    res.json({ success: true, token, user: sanitizeUser(user), isNewUser: true });
  } catch (error) {
    next(error);
  }
});

router.post('/login', async (req, res, next) => {
  try {
    const email = (req.body.email || '').trim().toLowerCase();
    const password = req.body.password;

    if (!isValidEmail(email) || typeof password !== 'string' || password.length === 0) {
      return res.status(401).json({ success: false, error: 'Invalid email or password' });
    }

    const user = await User.findOne({
      email: { $regex: new RegExp(`^${escapeRegex(email)}$`, 'i') },
    });

    if (!user || !user.passwordHash) {
      return res.status(401).json({ success: false, error: 'Invalid email or password' });
    }

    const isValidPassword = await bcrypt.compare(password, user.passwordHash);
    if (!isValidPassword) {
      return res.status(401).json({ success: false, error: 'Invalid email or password' });
    }

    user.isSessionActive = true;
    await user.save();

    const token = await issueAuthToken(user);
    res.json({ success: true, token, user: sanitizeUser(user), isNewUser: false });
  } catch (error) {
    next(error);
  }
});

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
      user = await User.findOne({ email: { $regex: new RegExp(`^${escapeRegex(verifiedEmail)}$`, 'i') } });
    }

    const isNewUser = !user;

    if (!user) {
      user = await User.create({
        googleId: verifiedGoogleId,
        email: verifiedEmail,
        username: customUsernameProvided ? username.trim() : `user_${Date.now()}`,
        hasCustomUsername: customUsernameProvided,
        authProviders: ['google'],
        role: verifiedEmail === 'anik78735@gmail.com' ? 'ADMIN' : 'USER',
        isSessionActive: true,
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
      const authProviders = Array.isArray(user.authProviders) ? user.authProviders : [];
      if (!authProviders.includes('google')) {
        authProviders.push('google');
        user.authProviders = authProviders;
      }
      user.isSessionActive = true;
      await user.save();
    }

    const token = await issueAuthToken(user);

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

// बदलकर ऐसा कर दें:
router.post('/google-login', handleGoogleLogin); // गूगल के लिए
router.post('/signup', handleGoogleLogin);       // Flutter ऐप के signup के लिए
router.post('/login', handleGoogleLogin);        // Flutter ऐप के login के लिए

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
