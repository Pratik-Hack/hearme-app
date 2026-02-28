const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const UserStats = require('../models/UserStats');
const RedeemedReward = require('../models/RedeemedReward');
const MindSpaceRecord = require('../models/MindSpaceRecord');

// ── User Stats ──────────────────────────────────────────────────────────────

// Get user stats
router.get('/stats', auth, async (req, res) => {
  try {
    let stats = await UserStats.findOne({ userId: req.user.id });
    if (!stats) {
      stats = new UserStats({ userId: req.user.id });
      await stats.save();
    }
    res.json(stats);
  } catch (error) {
    console.error('Get stats error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Sync user stats (save from client)
router.put('/stats', auth, async (req, res) => {
  try {
    const { coins, totalSessions, currentStreak, bestStreak, lastCheckin, lastChatReward, chatRewardCount } = req.body;

    let stats = await UserStats.findOne({ userId: req.user.id });
    if (!stats) {
      stats = new UserStats({ userId: req.user.id });
    }

    stats.coins = coins ?? stats.coins;
    stats.totalSessions = totalSessions ?? stats.totalSessions;
    stats.currentStreak = currentStreak ?? stats.currentStreak;
    stats.bestStreak = bestStreak ?? stats.bestStreak;
    stats.lastCheckin = lastCheckin ?? stats.lastCheckin;
    stats.lastChatReward = lastChatReward ?? stats.lastChatReward;
    stats.chatRewardCount = chatRewardCount ?? stats.chatRewardCount;
    stats.updatedAt = Date.now();

    await stats.save();
    res.json(stats);
  } catch (error) {
    console.error('Sync stats error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// ── Redeemed Rewards ────────────────────────────────────────────────────────

// Get all redeemed rewards for user
router.get('/redeemed', auth, async (req, res) => {
  try {
    const rewards = await RedeemedReward.find({ userId: req.user.id })
      .sort({ redeemedAt: -1 });
    res.json({ rewards });
  } catch (error) {
    console.error('Get redeemed rewards error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Save a redeemed reward
router.post('/redeemed', auth, async (req, res) => {
  try {
    const { rewardType, title, content, cost } = req.body;
    const reward = new RedeemedReward({
      userId: req.user.id,
      rewardType,
      title,
      content,
      cost,
    });
    await reward.save();
    res.status(201).json(reward);
  } catch (error) {
    console.error('Save redeemed reward error:', error);
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

// Save a MindSpace record
router.post('/mindspace', auth, async (req, res) => {
  try {
    const { response, transcript, urgency, coinsEarned } = req.body;
    const record = new MindSpaceRecord({
      userId: req.user.id,
      response,
      transcript,
      urgency,
      coinsEarned,
    });
    await record.save();
    res.status(201).json(record);
  } catch (error) {
    console.error('Save mindspace record error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
