const { v2: cloudinary } = require('cloudinary');
const { v2: secondaryCloudinary } = require('cloudinary');
const { google } = require('googleapis');
const { Readable } = require('stream');
const https = require('https');

const primaryCloud = cloudinary;
const secondaryCloud = secondaryCloudinary;

function configureCloudinary() {
  const configs = [
    {
      cloudName: process.env.CLOUDINARY_CLOUD_NAME,
      apiKey: process.env.CLOUDINARY_API_KEY,
      apiSecret: process.env.CLOUDINARY_API_SECRET,
    },
    {
      cloudName: process.env.CLOUDINARY_SECONDARY_CLOUD_NAME,
      apiKey: process.env.CLOUDINARY_SECONDARY_API_KEY,
      apiSecret: process.env.CLOUDINARY_SECONDARY_API_SECRET,
    },
  ];

  configs.forEach((config, index) => {
    if (config.cloudName && config.apiKey && config.apiSecret) {
      const target = index === 0 ? primaryCloud : secondaryCloud;
      target.config({
        cloud_name: config.cloudName,
        api_key: config.apiKey,
        api_secret: config.apiSecret,
      });
    }
  });
}

configureCloudinary();

function getDriveClient() {
  const auth = new google.auth.GoogleAuth({
    credentials: {
      client_email: process.env.GOOGLE_DRIVE_CLIENT_EMAIL,
      private_key: process.env.GOOGLE_DRIVE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    },
    scopes: ['https://www.googleapis.com/auth/drive.file'],
  });
  return google.drive({ version: 'v3', auth });
}

function uploadToCloudinary(buffer, filename, cloud) {
  return new Promise((resolve, reject) => {
    const uploadStream = cloud.uploader.upload_stream({
      resource_type: 'video',
      public_id: filename.replace(/\.[^/.]+$/, ''),
      folder: 'yt-uploader',
    }, (error, result) => {
      if (error) return reject(error);
      resolve({ provider: 'cloudinary', remoteFileId: result.public_id, url: result.secure_url });
    });

    const readable = new Readable();
    readable.push(buffer);
    readable.push(null);
    readable.pipe(uploadStream);
  });
}

async function downloadFromCloudinary(remoteFileId) {
  const url = primaryCloud.url(remoteFileId, { resource_type: 'video', secure: true });
  return await new Promise((resolve, reject) => {
    https.get(url, (response) => {
      if (response.statusCode && response.statusCode >= 400) {
        response.resume();
        return reject(new Error(`Cloudinary download failed with status ${response.statusCode}`));
      }
      resolve(response);
    }).on('error', reject);
  });
}

async function downloadVideo(provider, remoteFileId) {
  if (!provider || !remoteFileId) return null;

  if (provider === 'drive') {
    const drive = getDriveClient();
    const response = await drive.files.get({ fileId: remoteFileId, alt: 'media' }, { responseType: 'stream' });
    return response.data;
  }

  if (provider.includes('cloudinary')) {
    return downloadFromCloudinary(remoteFileId);
  }

  return null;
}

async function uploadToDrive(buffer, filename) {
  const drive = getDriveClient();
  const fileMetadata = {
    name: filename,
    parents: [process.env.GOOGLE_DRIVE_FOLDER_ID],
  };
  const media = {
    mimeType: 'video/mp4',
    body: Readable.from(buffer),
  };

  const response = await drive.files.create({
    requestBody: fileMetadata,
    media,
    fields: 'id,webViewLink',
  });

  return {
    provider: 'drive',
    remoteFileId: response.data.id,
    url: response.data.webViewLink,
  };
}

async function uploadVideo(buffer, filename) {
  try {
    return await uploadToCloudinary(buffer, filename, primaryCloud);
  } catch (error) {
    const message = String(error.message || error);
    if (message.includes('quota') || message.includes('storage') || message.includes('limit')) {
      try {
        return await uploadToCloudinary(buffer, filename, secondaryCloud);
      } catch (secondaryError) {
        return uploadToDrive(buffer, filename);
      }
    }
    try {
      return await uploadToCloudinary(buffer, filename, secondaryCloud);
    } catch (secondaryError) {
      return uploadToDrive(buffer, filename);
    }
  }
}

async function deleteVideo(provider, remoteFileId) {
  if (!provider || !remoteFileId) return;

  if (provider === 'drive') {
    const drive = getDriveClient();
    await drive.files.delete({ fileId: remoteFileId });
    return;
  }

  if (provider.includes('cloudinary')) {
    await primaryCloud.uploader.destroy(remoteFileId);
  }
}

module.exports = { uploadVideo, downloadVideo, deleteVideo };
