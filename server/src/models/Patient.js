const mongoose = require('mongoose');

const patientSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  dob: { type: String },
  bloodGroup: { type: String },
  emergencyContact: { type: String },
  linkedDoctor: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  medicalRecords: [{
    date: { type: Date, default: Date.now },
    type: String,
    summary: String,
    details: mongoose.Schema.Types.Mixed,
  }],
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('Patient', patientSchema);
