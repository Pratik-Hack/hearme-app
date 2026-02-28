const mongoose = require('mongoose');

const mentalHealthNotificationSchema = new mongoose.Schema({
  doctorId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true,
  },
  patientId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  patientName: {
    type: String,
    required: true,
  },
  clinicalReport: {
    type: String,
    required: true,
  },
  urgency: {
    type: String,
    enum: ['low', 'moderate', 'high'],
    default: 'low',
  },
  transcript: {
    type: String,
  },
  read: {
    type: Boolean,
    default: false,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('MentalHealthNotification', mentalHealthNotificationSchema);
