const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const User = require('../models/User');
const Patient = require('../models/Patient');
const Doctor = require('../models/Doctor');

// Get user profile
router.get('/profile', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const profile = {
      id: user._id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      role: user.role,
      uniqueCode: user.uniqueCode,
      createdAt: user.createdAt,
    };

    // Attach role-specific data
    if (user.role === 'patient') {
      const patient = await Patient.findOne({ userId: user._id });
      if (patient) {
        profile.dob = patient.dob;
        profile.bloodGroup = patient.bloodGroup;
        profile.emergencyContact = patient.emergencyContact;
      }
    } else if (user.role === 'doctor') {
      const doctor = await Doctor.findOne({ userId: user._id });
      if (doctor) {
        profile.specialization = doctor.specialization;
        profile.licenseNumber = doctor.licenseNumber;
        profile.hospital = doctor.hospital;
        profile.patientCount = doctor.patients ? doctor.patients.length : 0;
      }
    }

    res.json(profile);
  } catch (error) {
    console.error('Profile error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Update user profile
router.put('/profile', auth, async (req, res) => {
  try {
    const { name, phone, dob, bloodGroup, emergencyContact, specialization, licenseNumber, hospital } = req.body;

    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Update common fields
    if (name) user.name = name;
    if (phone !== undefined) user.phone = phone;
    await user.save();

    // Update role-specific fields
    if (user.role === 'patient') {
      await Patient.findOneAndUpdate(
        { userId: user._id },
        { dob, bloodGroup, emergencyContact },
        { upsert: true }
      );
    } else if (user.role === 'doctor') {
      await Doctor.findOneAndUpdate(
        { userId: user._id },
        { specialization, licenseNumber, hospital },
        { upsert: true }
      );
    }

    res.json({ message: 'Profile updated' });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
