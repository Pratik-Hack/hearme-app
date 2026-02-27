const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const VitalsSummary = require('../models/VitalsSummary');

// Save vitals session summary
router.post('/summary', auth, async (req, res) => {
  try {
    const summary = new VitalsSummary({
      patientId: req.user.id,
      ...req.body,
    });
    await summary.save();
    res.status(201).json({ message: 'Summary saved', id: summary._id });
  } catch (error) {
    console.error('Save summary error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get vitals summaries for patient
router.get('/summaries', auth, async (req, res) => {
  try {
    const summaries = await VitalsSummary.find({ patientId: req.user.id })
      .sort({ createdAt: -1 })
      .limit(20);
    res.json({ summaries });
  } catch (error) {
    console.error('Get summaries error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
