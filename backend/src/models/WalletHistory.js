const mongoose = require('mongoose');

const WalletHistorySchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  walletId: { type: mongoose.Schema.Types.ObjectId, ref: 'Wallet', required: true },
  transactionType: { type: String, enum: ['PURCHASE', 'CREDIT', 'DEBIT', 'REFUND', 'ADMIN_ADJUST'], required: true },
  diamondAmount: { type: Number, required: true },
  beforeBalance: { type: Number, required: true },
  afterBalance: { type: Number, required: true },
  description: { type: String, default: '' },
  relatedTransactionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Transaction', default: null },
  relatedPaymentId: { type: mongoose.Schema.Types.ObjectId, ref: 'PaymentRequest', default: null },
  reference: { type: String, default: '' },
}, { timestamps: true });

module.exports = mongoose.model('WalletHistory', WalletHistorySchema);
