const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const roleCheck = require('../middleware/roleCheck');
const Doctor = require('../models/Doctor');
const User = require('../models/User');

// Get doctor's patients
router.get('/patients', auth, roleCheck('doctor'), async (req, res) => {
  try {
    const doctor = await Doctor.findOne({ userId: req.user.id }).populate({
      path: 'patients',
      select: 'name email phone uniqueCode',
    });

    if (!doctor) {
      return res.status(404).json({ message: 'Doctor profile not found' });
    }

    res.json({ patients: doctor.patients || [] });
  } catch (error) {
    console.error('Get patients error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
