const mongoose = require('mongoose');

const WalletSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
  currentDiamonds: { type: Number, default: 0 },
  lifetimeDiamondsPurchased: { type: Number, default: 0 },
  lifetimeDiamondsUsed: { type: Number, default: 0 },
  totalSpent: { type: Number, default: 0 },
  pendingRequests: { type: Number, default: 0 },
  rejectedRequests: { type: Number, default: 0 },
  lastPurchaseDate: { type: Date, default: null },
  lastRefillDate: { type: Date, default: null },
}, { timestamps: true });

module.exports = mongoose.model('Wallet', WalletSchema);
