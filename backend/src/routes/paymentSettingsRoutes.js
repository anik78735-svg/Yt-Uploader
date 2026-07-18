const express = require('express');
const router = express.Router();
const PaymentSettings = require('../models/PaymentSettings');
const { requireAuth, requireAdmin } = require('../middleware/auth');

// Public endpoint - Get current payment settings
router.get('/settings', async (req, res, next) => {
  try {
    let settings = await PaymentSettings.findOne();
    
    if (!settings) {
      // Create default settings if none exist
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
    
    res.json({ success: true, settings });
  } catch (error) {
    next(error);
  }
});

// Admin endpoints
router.use(requireAuth);
router.use(requireAdmin);

// Get current payment settings (admin)
router.get('/admin/settings', async (req, res, next) => {
  try {
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
    res.json({ success: true, settings });
  } catch (error) {
    next(error);
  }
});

// Update payment settings (admin)
router.put('/admin/settings', async (req, res, next) => {
  try {
    const { merchantName, upiId, paymentInstructions, supportWhatsapp, supportEmail, diamondPackages, enableAutoRefill, autoRefillThreshold, autoRefillAmount } = req.body;
    
    let settings = await PaymentSettings.findOne();
    if (!settings) {
      settings = new PaymentSettings();
    }
    
    if (merchantName) settings.merchantName = merchantName;
    if (upiId) settings.upiId = upiId;
    if (paymentInstructions) settings.paymentInstructions = paymentInstructions;
    if (supportWhatsapp) settings.supportWhatsapp = supportWhatsapp;
    if (supportEmail) settings.supportEmail = supportEmail;
    if (diamondPackages) settings.diamondPackages = diamondPackages;
    if (enableAutoRefill !== undefined) settings.enableAutoRefill = enableAutoRefill;
    if (autoRefillThreshold) settings.autoRefillThreshold = autoRefillThreshold;
    if (autoRefillAmount) settings.autoRefillAmount = autoRefillAmount;
    
    await settings.save();
    res.json({ success: true, settings });
  } catch (error) {
    next(error);
  }
});

// Upload QR Code (admin) - requires multer middleware
router.post('/admin/upload-qr', async (req, res, next) => {
  try {
    // This endpoint expects a file to be uploaded via multipart/form-data
    // The actual file upload handling would be done by multer middleware
    // For now, we'll just update the URL
    const { qrImageUrl } = req.body;
    
    let settings = await PaymentSettings.findOne();
    if (!settings) {
      return res.status(404).json({ success: false, error: 'Settings not found' });
    }
    
    if (qrImageUrl) {
      settings.qrImageUrl = qrImageUrl;
      await settings.save();
    }
    
    res.json({ success: true, settings });
  } catch (error) {
    next(error);
  }
});

// Toggle package status (admin)
router.post('/admin/toggle-package/:packageId', async (req, res, next) => {
  try {
    const { packageId } = req.params;
    
    let settings = await PaymentSettings.findOne();
    if (!settings) {
      return res.status(404).json({ success: false, error: 'Settings not found' });
    }
    
    const pkg = settings.diamondPackages.find(p => p.packageId === packageId);
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

// Update package price (admin)
router.post('/admin/update-package', async (req, res, next) => {
  try {
    const { packageId, price, badge } = req.body;
    
    let settings = await PaymentSettings.findOne();
    if (!settings) {
      return res.status(404).json({ success: false, error: 'Settings not found' });
    }
    
    const pkg = settings.diamondPackages.find(p => p.packageId === packageId);
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
