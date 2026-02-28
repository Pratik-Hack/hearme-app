const mongoose = require('mongoose');

const userStatsSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
  coins: { type: Number, default: 0 },
  totalSessions: { type: Number, default: 0 },
  currentStreak: { type: Number, default: 0 },
  bestStreak: { type: Number, default: 0 },
  lastCheckin: { type: String },
  lastChatReward: { type: String },
  chatRewardCount: { type: Number, default: 0 },
  updatedAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('UserStats', userStatsSchema);
