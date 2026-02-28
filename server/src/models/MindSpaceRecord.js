const mongoose = require('mongoose');

const mindSpaceRecordSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  response: { type: String, required: true },
  transcript: { type: String },
  urgency: { type: String, default: 'low' },
  coinsEarned: { type: Number, default: 0 },
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('MindSpaceRecord', mindSpaceRecordSchema);
