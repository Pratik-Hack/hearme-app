import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CoinsProvider extends ChangeNotifier {
  static const String _coinsKey = 'mind_coins';
  static const String _sessionsKey = 'total_sessions';
  static const String _streakKey = 'current_streak';
  static const String _bestStreakKey = 'best_streak';
  static const String _lastCheckinKey = 'last_checkin';
  static const String _lastChatRewardKey = 'last_chat_reward';
  static const String _chatRewardCountKey = 'chat_reward_count';

  int _coins = 0;
  int _totalSessions = 0;
  int _currentStreak = 0;
  int _bestStreak = 0;
  String? _lastCheckin;
  String? _lastChatReward;
  int _chatRewardCount = 0;

  CoinsProvider() {
    _loadFromStorage();
  }

  int get coins => _coins;
  int get totalSessions => _totalSessions;
  int get currentStreak => _currentStreak;
  int get bestStreak => _bestStreak;

  bool get checkedInToday {
    if (_lastCheckin == null) return false;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return _lastCheckin == today;
  }

  bool get chatRewardedToday {
    if (_lastChatReward == null) return false;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return _lastChatReward == today && _chatRewardCount >= 5;
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _coins = prefs.getInt(_coinsKey) ?? 0;
    _totalSessions = prefs.getInt(_sessionsKey) ?? 0;
    _currentStreak = prefs.getInt(_streakKey) ?? 0;
    _bestStreak = prefs.getInt(_bestStreakKey) ?? 0;
    _lastCheckin = prefs.getString(_lastCheckinKey);
    _lastChatReward = prefs.getString(_lastChatRewardKey);
    _chatRewardCount = prefs.getInt(_chatRewardCountKey) ?? 0;
    notifyListeners();
  }

  Future<int> addCoins(int amount) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    int totalEarned = amount;

    // Update streak
    if (_lastCheckin != null) {
      final lastDate = DateTime.parse(_lastCheckin!);
      final todayDate = DateTime.parse(today);
      final diff = todayDate.difference(lastDate).inDays;

      if (diff == 1) {
        _currentStreak++;
      } else if (diff > 1) {
        _currentStreak = 1;
      }
    } else {
      _currentStreak = 1;
    }

    // Streak bonuses
    if (_currentStreak == 3) totalEarned += 15;
    if (_currentStreak == 7) totalEarned += 50;

    if (_currentStreak > _bestStreak) _bestStreak = _currentStreak;

    _coins += totalEarned;
    _totalSessions++;
    _lastCheckin = today;

    await _saveToStorage();
    notifyListeners();
    return totalEarned;
  }

  Future<int> addChatCoins() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (_lastChatReward != today) {
      _lastChatReward = today;
      _chatRewardCount = 0;
    }

    if (_chatRewardCount >= 5) return 0;

    _chatRewardCount++;
    _coins += 1;

    await _saveToStorage();
    notifyListeners();
    return 1;
  }

  Future<bool> spendCoins(int amount) async {
    if (_coins < amount) return false;
    _coins -= amount;
    await _saveToStorage();
    notifyListeners();
    return true;
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_coinsKey, _coins);
    await prefs.setInt(_sessionsKey, _totalSessions);
    await prefs.setInt(_streakKey, _currentStreak);
    await prefs.setInt(_bestStreakKey, _bestStreak);
    if (_lastCheckin != null) {
      await prefs.setString(_lastCheckinKey, _lastCheckin!);
    }
    if (_lastChatReward != null) {
      await prefs.setString(_lastChatRewardKey, _lastChatReward!);
    }
    await prefs.setInt(_chatRewardCountKey, _chatRewardCount);
  }
}
