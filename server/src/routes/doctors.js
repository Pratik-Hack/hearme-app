const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const roleCheck = require('../middleware/roleCheck');
const Doctor = require('../models/Doctor');
const User = require('../models/User');
const MindSpaceRecord = require('../models/MindSpaceRecord');
const ChatSession = require('../models/ChatSession');

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

// Helper: verify doctor has access to this patient
async function verifyDoctorPatient(doctorUserId, patientUserId) {
  const doctor = await Doctor.findOne({ userId: doctorUserId });
  if (!doctor) return false;
  return doctor.patients.some(p => p.toString() === patientUserId);
}

// Get a patient's MindSpace records (for doctor)
router.get('/patients/:patientId/mindspace', auth, roleCheck('doctor'), async (req, res) => {
  try {
    const hasAccess = await verifyDoctorPatient(req.user.id, req.params.patientId);
    if (!hasAccess) {
      return res.status(403).json({ message: 'Not your patient' });
    }

    const records = await MindSpaceRecord.find({ userId: req.params.patientId })
      .sort({ createdAt: -1 });
    res.json({ records });
  } catch (error) {
    console.error('Get patient mindspace error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get a patient's chat sessions (for doctor)
router.get('/patients/:patientId/chats', auth, roleCheck('doctor'), async (req, res) => {
  try {
    const hasAccess = await verifyDoctorPatient(req.user.id, req.params.patientId);
    if (!hasAccess) {
      return res.status(403).json({ message: 'Not your patient' });
    }

    const sessions = await ChatSession.find({ userId: req.params.patientId })
      .sort({ updatedAt: -1 })
      .select('sessionId title createdAt updatedAt messages');
    res.json({ sessions });
  } catch (error) {
    console.error('Get patient chats error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
