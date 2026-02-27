const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const roleCheck = require('../middleware/roleCheck');
const Patient = require('../models/Patient');
const Doctor = require('../models/Doctor');
const User = require('../models/User');

// Link to doctor
router.post('/link', auth, roleCheck('patient'), async (req, res) => {
  try {
    const { doctorCode } = req.body;

    // Find doctor by unique code
    const doctorUser = await User.findOne({ uniqueCode: doctorCode, role: 'doctor' });
    if (!doctorUser) {
      return res.status(404).json({ message: 'Doctor not found with this code' });
    }

    // Update patient's linked doctor
    const patient = await Patient.findOne({ userId: req.user.id });
    if (!patient) {
      return res.status(404).json({ message: 'Patient profile not found' });
    }

    patient.linkedDoctor = doctorUser._id;
    await patient.save();

    // Add patient to doctor's list
    const doctor = await Doctor.findOne({ userId: doctorUser._id });
    if (doctor && !doctor.patients.includes(req.user.id)) {
      doctor.patients.push(req.user.id);
      await doctor.save();
    }

    res.json({
      message: 'Successfully linked to doctor',
      doctor: { id: doctorUser._id, name: doctorUser.name },
    });
  } catch (error) {
    console.error('Link doctor error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get linked doctor
router.get('/doctor', auth, roleCheck('patient'), async (req, res) => {
  try {
    const patient = await Patient.findOne({ userId: req.user.id });
    if (!patient || !patient.linkedDoctor) {
      return res.json({ doctor: null });
    }

    const doctor = await User.findById(patient.linkedDoctor).select('-password');
    res.json({
      doctor: doctor ? {
        id: doctor._id,
        name: doctor.name,
        email: doctor.email,
        uniqueCode: doctor.uniqueCode,
      } : null,
    });
  } catch (error) {
    console.error('Get doctor error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get medical records
router.get('/records', auth, roleCheck('patient'), async (req, res) => {
  try {
    const patient = await Patient.findOne({ userId: req.user.id });
    if (!patient) {
      return res.status(404).json({ message: 'Patient profile not found' });
    }
    res.json({ records: patient.medicalRecords || [] });
  } catch (error) {
    console.error('Get records error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get medical summary (for chatbot context)
router.get('/medical-summary', auth, roleCheck('patient'), async (req, res) => {
  try {
    const patient = await Patient.findOne({ userId: req.user.id });
    const user = await User.findById(req.user.id).select('-password');

    if (!patient || !user) {
      return res.json({ summary: null });
    }

    const summary = {
      name: user.name,
      bloodGroup: patient.bloodGroup,
      dob: patient.dob,
      recentRecords: (patient.medicalRecords || []).slice(-5),
    };

    res.json({ summary: JSON.stringify(summary) });
  } catch (error) {
    console.error('Medical summary error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
