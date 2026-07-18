const { google } = require('googleapis');
const { encryptToken, decryptToken } = require('../utils/crypto');

const youtubeOAuthClient = new google.auth.OAuth2(
  process.env.YOUTUBE_CLIENT_ID,
  process.env.YOUTUBE_CLIENT_SECRET,
  'https://developers.google.com/oauthplayground'
);

function getYoutubeClientForUser(user) {
  if (!user || !user.encryptedRefreshToken) {
    throw new Error('YouTube authorization is not configured for this user');
  }

  const client = new google.auth.OAuth2(
    process.env.YOUTUBE_CLIENT_ID,
    process.env.YOUTUBE_CLIENT_SECRET,
    'https://developers.google.com/oauthplayground'
  );

  client.setCredentials({
    refresh_token: decryptToken(user.encryptedRefreshToken),
  });

  return google.youtube({ version: 'v3', auth: client });
}

module.exports = { youtubeOAuthClient, getYoutubeClientForUser };
