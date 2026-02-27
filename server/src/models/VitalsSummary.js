const mongoose = require('mongoose');

const vitalsSummarySchema = new mongoose.Schema({
  patientId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  sessionId: { type: String, required: true },
  duration: { type: Number },
  averages: {
    heartRate: Number,
    systolic: Number,
    diastolic: Number,
    spo2: Number,
    temperature: Number,
    respiratoryRate: Number,
  },
  alerts: [{
    severity: String,
    vitalType: String,
    message: String,
    timestamp: Date,
  }],
  scenario: { type: String },
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('VitalsSummary', vitalsSummarySchema);
