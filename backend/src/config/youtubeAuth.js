const { google } = require('googleapis');
const { encryptToken, decryptToken } = require('../utils/crypto');

const YOUTUBE_REDIRECT_URI = process.env.YOUTUBE_REDIRECT_URI || 'https://yt-uploader-3ulo.onrender.com/api/auth/youtube-callback';

const youtubeOAuthClient = new google.auth.OAuth2(
  process.env.YOUTUBE_CLIENT_ID,
  process.env.YOUTUBE_CLIENT_SECRET,
  YOUTUBE_REDIRECT_URI
);

function getYoutubeClientForUser(user) {
  if (!user || !user.encryptedRefreshToken) {
    throw new Error('YouTube authorization is not configured for this user');
  }

  const client = new google.auth.OAuth2(
    process.env.YOUTUBE_CLIENT_ID,
    process.env.YOUTUBE_CLIENT_SECRET,
    YOUTUBE_REDIRECT_URI
  );

  client.setCredentials({
    refresh_token: decryptToken(user.encryptedRefreshToken),
  });

  return google.youtube({ version: 'v3', auth: client });
}

module.exports = { youtubeOAuthClient, getYoutubeClientForUser };
