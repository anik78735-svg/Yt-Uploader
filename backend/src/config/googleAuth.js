const { OAuth2Client } = require('google-auth-library');

const googleAuthClient = new OAuth2Client(
  process.env.GOOGLE_CLIENT_ID,
  process.env.GOOGLE_CLIENT_SECRET
);

module.exports = googleAuthClient;
