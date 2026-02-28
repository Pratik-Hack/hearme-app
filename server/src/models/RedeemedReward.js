const mongoose = require('mongoose');

const redeemedRewardSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  rewardType: { type: String, required: true },
  title: { type: String, required: true },
  content: { type: String, required: true },
  cost: { type: Number, required: true },
  redeemedAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('RedeemedReward', redeemedRewardSchema);
