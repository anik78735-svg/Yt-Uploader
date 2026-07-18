const mongoose = require('mongoose');

const PaymentRequestSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  paymentId: { type: String, required: true, unique: true, index: true },
  packageId: { type: String, required: true },
  diamonds: { type: Number, required: true },
  amount: { type: Number, required: true },
  status: { type: String, enum: ['PENDING', 'APPROVED', 'REJECTED', 'EXPIRED'], default: 'PENDING' },
  secureToken: { type: String, required: true },
  ipAddress: { type: String, default: '' },
  userAgent: { type: String, default: '' },
  generatedAt: { type: Date, default: Date.now, index: true, expires: 86400 }, // 24 hour expiry
  approvedAt: { type: Date, default: null },
  rejectionReason: { type: String, default: '' },
  rejectedAt: { type: Date, default: null },
  approvedByAdmin: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  notes: { type: String, default: '' },
}, { timestamps: true });

module.exports = mongoose.model('PaymentRequest', PaymentRequestSchema);
