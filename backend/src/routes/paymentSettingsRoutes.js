const express = require('express');
const fs = require('fs');
const path = require('path');
const multer = require('multer');
const { v2: cloudinary } = require('cloudinary');
const router = express.Router();
const PaymentSettings = require('../models/PaymentSettings');
const { requireAuth, requireAdmin } = require('../middleware/auth');

const uploadDir = path.resolve(__dirname, '../../uploads/qr');
fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || '.png';
    cb(null, `qr-${Date.now()}-${Math.round(Math.random() * 1e9)}${ext}`);
  },
});

const upload = multer({ storage, limits: { fileSize: 5 * 1024 * 1024 } });

if (process.env.CLOUDINARY_CLOUD_NAME && process.env.CLOUDINARY_API_KEY && process.env.CLOUDINARY_API_SECRET) {
  cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
  });
}

async function getOrCreateSettings() {
  let settings = await PaymentSettings.findOne();
  if (!settings) {
    settings = await PaymentSettings.create({
      merchantName: 'YT Uploader',
      upiId: 'uploader@okhdfcbank',
      qrImageUrl: 'https://via.placeholder.com/300?text=QR+Code',
      paymentInstructions: 'Scan QR code or enter UPI ID to send payment',
      diamondPackages: [
        { packageId: 'pkg_100', diamonds: 100, price: 99, badge: 'NONE', enabled: true },
        { packageId: 'pkg_500', diamonds: 500, price: 399, badge: 'POPULAR', enabled: true },
        { packageId: 'pkg_1000', diamonds: 1000, price: 699, badge: 'NONE', enabled: true },
        { packageId: 'pkg_5000', diamonds: 5000, price: 2999, badge: 'DISCOUNT', enabled: true },
      ],
    });
  }
  return settings;
}

function buildBaseUrl(req) {
  return process.env.PUBLIC_BASE_URL || `${req.protocol}://${req.get('host')}`;
}

async function storeQrFile(req, file) {
  if (!file) return null;

  if (process.env.CLOUDINARY_CLOUD_NAME && process.env.CLOUDINARY_API_KEY && process.env.CLOUDINARY_API_SECRET) {
    const uploadResponse = await cloudinary.uploader.upload(file.path, {
      folder: 'yt-uploader/qr',
      resource_type: 'image',
    });
    fs.unlinkSync(file.path);
    return uploadResponse.secure_url;
  }

  return `${buildBaseUrl(req)}/uploads/qr/${file.filename}`;
}

// Public endpoint - Get current payment settings
router.get('/settings', async (req, res, next) => {
  try {
    const settings = await getOrCreateSettings();
    res.json({ success: true, settings });
  } catch (error) {
    next(error);
  }
});

// Admin endpoints
router.use(requireAuth);
router.use(requireAdmin);

router.get('/', async (req, res, next) => {
  try {
    const settings = await getOrCreateSettings();
    res.json({ success: true, settings });
  } catch (error) {
    next(error);
  }
});

router.get('/admin/settings', async (req, res, next) => {
  try {
    const settings = await getOrCreateSettings();
    res.json({ success: true, settings });
  } catch (error) {
    next(error);
  }
});

router.put('/', upload.single('qrImage'), async (req, res, next) => {
  try {
    const { merchantName, upiId, paymentInstructions, supportWhatsapp, supportEmail, diamondPackages, enableAutoRefill, autoRefillThreshold, autoRefillAmount } = req.body;
    const settings = await getOrCreateSettings();

    if (merchantName) settings.merchantName = merchantName;
    if (upiId) settings.upiId = upiId;
    if (paymentInstructions) settings.paymentInstructions = paymentInstructions;
    if (supportWhatsapp) settings.supportWhatsapp = supportWhatsapp;
    if (supportEmail) settings.supportEmail = supportEmail;
    if (diamondPackages) settings.diamondPackages = diamondPackages;
    if (enableAutoRefill !== undefined) settings.enableAutoRefill = enableAutoRefill;
    if (autoRefillThreshold !== undefined) settings.autoRefillThreshold = autoRefillThreshold;
    if (autoRefillAmount !== undefined) settings.autoRefillAmount = autoRefillAmount;

    if (req.file) {
      settings.qrImageUrl = await storeQrFile(req, req.file);
    }

    await settings.save();
    res.json({ success: true, settings });
  } catch (error) {
    next(error);
  }
});

router.put('/admin/settings', upload.single('qrImage'), async (req, res, next) => {
  try {
    const { merchantName, upiId, paymentInstructions, supportWhatsapp, supportEmail, diamondPackages, enableAutoRefill, autoRefillThreshold, autoRefillAmount } = req.body;
    const settings = await getOrCreateSettings();

    if (merchantName) settings.merchantName = merchantName;
    if (upiId) settings.upiId = upiId;
    if (paymentInstructions) settings.paymentInstructions = paymentInstructions;
    if (supportWhatsapp) settings.supportWhatsapp = supportWhatsapp;
    if (supportEmail) settings.supportEmail = supportEmail;
    if (diamondPackages) settings.diamondPackages = diamondPackages;
    if (enableAutoRefill !== undefined) settings.enableAutoRefill = enableAutoRefill;
    if (autoRefillThreshold !== undefined) settings.autoRefillThreshold = autoRefillThreshold;
    if (autoRefillAmount !== undefined) settings.autoRefillAmount = autoRefillAmount;

    if (req.file) {
      settings.qrImageUrl = await storeQrFile(req, req.file);
    }

    await settings.save();
    res.json({ success: true, settings });
  } catch (error) {
    next(error);
  }
});

router.post('/upload-qr', upload.single('qrImage'), async (req, res, next) => {
  try {
    const { qrImageUrl } = req.body;
    const settings = await getOrCreateSettings();

    if (qrImageUrl) {
      settings.qrImageUrl = qrImageUrl;
    } else if (req.file) {
      settings.qrImageUrl = await storeQrFile(req, req.file);
    }

    await settings.save();
    res.json({ success: true, settings });
  } catch (error) {
    next(error);
  }
});

router.post('/admin/upload-qr', upload.single('qrImage'), async (req, res, next) => {
  try {
    const { qrImageUrl } = req.body;
    const settings = await getOrCreateSettings();

    if (qrImageUrl) {
      settings.qrImageUrl = qrImageUrl;
    } else if (req.file) {
      settings.qrImageUrl = await storeQrFile(req, req.file);
    }

    await settings.save();
    res.json({ success: true, settings });
  } catch (error) {
    next(error);
  }
});

router.post('/admin/toggle-package/:packageId', async (req, res, next) => {
  try {
    const { packageId } = req.params;
    const settings = await getOrCreateSettings();
    const pkg = settings.diamondPackages.find((p) => p.packageId === packageId);

    if (!pkg) {
      return res.status(404).json({ success: false, error: 'Package not found' });
    }

    pkg.enabled = !pkg.enabled;
    await settings.save();
    res.json({ success: true, settings });
  } catch (error) {
    next(error);
  }
});

router.post('/admin/update-package', async (req, res, next) => {
  try {
    const { packageId, price, badge } = req.body;
    const settings = await getOrCreateSettings();
    const pkg = settings.diamondPackages.find((p) => p.packageId === packageId);

    if (!pkg) {
      return res.status(404).json({ success: false, error: 'Package not found' });
    }

    if (price) pkg.price = price;
    if (badge) pkg.badge = badge;

    await settings.save();
    res.json({ success: true, settings });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
