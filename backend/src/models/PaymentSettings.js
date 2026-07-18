const mongoose = require('mongoose');

const PaymentSettingsSchema = new mongoose.Schema({
  merchantName: { type: String, required: true, default: 'YT Uploader' },
  upiId: { type: String, required: true },
  qrImageUrl: { type: String, required: true },
  paymentInstructions: { type: String, default: 'Scan QR code or enter UPI ID to complete payment' },
  supportWhatsapp: { type: String, default: '' },
  supportEmail: { type: String, default: '' },
  diamondPackages: [{
    packageId: { type: String, required: true },
    diamonds: { type: Number, required: true },
    price: { type: Number, required: true },
    badge: { type: String, enum: ['POPULAR', 'DISCOUNT', 'PREMIUM', 'NONE'], default: 'NONE' },
    enabled: { type: Boolean, default: true },
  }],
  enableAutoRefill: { type: Boolean, default: false },
  autoRefillThreshold: { type: Number, default: 50 },
  autoRefillAmount: { type: Number, default: 100 },
  isActive: { type: Boolean, default: true },
}, { timestamps: true });

module.exports = mongoose.model('PaymentSettings', PaymentSettingsSchema);
