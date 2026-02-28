const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const roleCheck = require('../middleware/roleCheck');
const MentalHealthNotification = require('../models/MentalHealthNotification');

// POST /api/mental-health/notifications — called by the chatbot server to save a notification
router.post('/notifications', async (req, res) => {
  try {
    const { doctorId, patientId, patientName, clinicalReport, urgency, transcript } = req.body;

    if (!doctorId || !patientId || !clinicalReport) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const notification = await MentalHealthNotification.create({
      doctorId,
      patientId,
      patientName: patientName || 'Patient',
      clinicalReport,
      urgency: urgency || 'low',
      transcript: transcript || '',
      read: false,
    });

    res.status(201).json({ notification });
  } catch (error) {
    console.error('Create notification error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// GET /api/mental-health/notifications — doctor fetches their notifications
router.get('/notifications', auth, roleCheck('doctor'), async (req, res) => {
  try {
    const notifications = await MentalHealthNotification.find({ doctorId: req.user.id })
      .sort({ createdAt: -1 });

    res.json({ notifications });
  } catch (error) {
    console.error('Get notifications error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// GET /api/mental-health/notifications/patient/:patientId — doctor fetches notifications for a specific patient
router.get('/notifications/patient/:patientId', auth, roleCheck('doctor'), async (req, res) => {
  try {
    const notifications = await MentalHealthNotification.find({
      doctorId: req.user.id,
      patientId: req.params.patientId,
    }).sort({ createdAt: -1 });

    res.json({ notifications });
  } catch (error) {
    console.error('Get patient notifications error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// PUT /api/mental-health/notifications/:id/read — mark a notification as read
router.put('/notifications/:id/read', auth, async (req, res) => {
  try {
    const notification = await MentalHealthNotification.findByIdAndUpdate(
      req.params.id,
      { read: true },
      { new: true },
    );

    if (!notification) {
      return res.status(404).json({ message: 'Notification not found' });
    }

    res.json({ message: 'Marked as read' });
  } catch (error) {
    console.error('Mark as read error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
