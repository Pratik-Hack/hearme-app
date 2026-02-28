const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const ChatSession = require('../models/ChatSession');
const MindSpaceRecord = require('../models/MindSpaceRecord');

// ── Chat Sessions ───────────────────────────────────────────────────────────

// Get all chat sessions for user
router.get('/chats', auth, async (req, res) => {
  try {
    const sessions = await ChatSession.find({ userId: req.user.id })
      .sort({ updatedAt: -1 })
      .select('sessionId title createdAt updatedAt messages');
    res.json({ sessions });
  } catch (error) {
    console.error('Get chat sessions error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Save or update a chat session
router.post('/chats', auth, async (req, res) => {
  try {
    const { sessionId, title, messages } = req.body;

    let session = await ChatSession.findOne({ userId: req.user.id, sessionId });
    if (session) {
      session.messages = messages;
      session.title = title || session.title;
      session.updatedAt = Date.now();
    } else {
      session = new ChatSession({
        userId: req.user.id,
        sessionId,
        title,
        messages,
      });
    }

    await session.save();
    res.status(201).json(session);
  } catch (error) {
    console.error('Save chat session error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Delete a chat session
router.delete('/chats/:id', auth, async (req, res) => {
  try {
    const result = await ChatSession.findOneAndDelete({
      _id: req.params.id,
      userId: req.user.id,
    });
    if (!result) {
      return res.status(404).json({ message: 'Session not found' });
    }
    res.json({ message: 'Deleted' });
  } catch (error) {
    console.error('Delete chat session error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// ── MindSpace Records ───────────────────────────────────────────────────────

// Get all MindSpace records for user
router.get('/mindspace', auth, async (req, res) => {
  try {
    const records = await MindSpaceRecord.find({ userId: req.user.id })
      .sort({ createdAt: -1 });
    res.json({ records });
  } catch (error) {
    console.error('Get mindspace records error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Delete a MindSpace record
router.delete('/mindspace/:id', auth, async (req, res) => {
  try {
    const result = await MindSpaceRecord.findOneAndDelete({
      _id: req.params.id,
      userId: req.user.id,
    });
    if (!result) {
      return res.status(404).json({ message: 'Record not found' });
    }
    res.json({ message: 'Deleted' });
  } catch (error) {
    console.error('Delete mindspace record error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
