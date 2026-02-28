import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hearme/services/api_service.dart';
import 'package:hearme/core/constants/api_constants.dart';

class CoinsProvider extends ChangeNotifier {
  static const String _coinsKey = 'mind_coins';
  static const String _sessionsKey = 'total_sessions';
  static const String _streakKey = 'current_streak';
  static const String _bestStreakKey = 'best_streak';
  static const String _lastCheckinKey = 'last_checkin';
  static const String _lastChatRewardKey = 'last_chat_reward';
  static const String _chatRewardCountKey = 'chat_reward_count';
  static const String _dailyTasksKey = 'daily_tasks';

  int _coins = 0;
  int _totalSessions = 0;
  int _currentStreak = 0;
  int _bestStreak = 0;
  String? _lastCheckin;
  String? _lastChatReward;
  int _chatRewardCount = 0;

  // Daily task tracking
  bool _mindSpaceDone = false;
  bool _chatDone = false;
  String? _dailyTaskDate;

  CoinsProvider() {
    _loadFromStorage();
  }

  int get coins => _coins;
  int get totalSessions => _totalSessions;
  int get currentStreak => _currentStreak;
  int get bestStreak => _bestStreak;
  bool get mindSpaceDone => _mindSpaceDone;
  bool get chatDone => _chatDone;

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

    // Load daily tasks
    final taskData = prefs.getString(_dailyTasksKey);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (taskData != null && taskData.startsWith(today)) {
      final parts = taskData.split('|');
      _dailyTaskDate = parts[0];
      _mindSpaceDone = parts.length > 1 && parts[1] == '1';
      _chatDone = parts.length > 2 && parts[2] == '1';
    } else {
      _dailyTaskDate = today;
      _mindSpaceDone = false;
      _chatDone = false;
    }

    notifyListeners();
  }

  /// Load stats from MongoDB (call after login)
  Future<void> loadFromServer() async {
    try {
      final data = await ApiService.get(ApiConstants.rewardsStats);
      if (data['coins'] != null) {
        _coins = data['coins'] ?? _coins;
        _totalSessions = data['totalSessions'] ?? _totalSessions;
        _currentStreak = data['currentStreak'] ?? _currentStreak;
        _bestStreak = data['bestStreak'] ?? _bestStreak;
        _lastCheckin = data['lastCheckin'];
        _lastChatReward = data['lastChatReward'];
        _chatRewardCount = data['chatRewardCount'] ?? 0;
        await _saveToStorage();
        notifyListeners();
      }
    } catch (_) {
      // Use local cache if server unreachable
    }
  }

  /// Sync stats to MongoDB
  Future<void> _syncToServer() async {
    try {
      await ApiService.put(ApiConstants.rewardsStats, body: {
        'coins': _coins,
        'totalSessions': _totalSessions,
        'currentStreak': _currentStreak,
        'bestStreak': _bestStreak,
        'lastCheckin': _lastCheckin,
        'lastChatReward': _lastChatReward,
        'chatRewardCount': _chatRewardCount,
      });
    } catch (_) {
      // Silently fail — local cache is primary
    }
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

    // Mark MindSpace daily task as done
    _checkDailyTaskDate();
    _mindSpaceDone = true;

    await _saveToStorage();
    _syncToServer();
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

    // Mark chat daily task as done
    _checkDailyTaskDate();
    _chatDone = true;

    await _saveToStorage();
    _syncToServer();
    notifyListeners();
    return 1;
  }

  Future<bool> spendCoins(int amount) async {
    if (_coins < amount) return false;
    _coins -= amount;
    await _saveToStorage();
    _syncToServer();
    notifyListeners();
    return true;
  }

  void _checkDailyTaskDate() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (_dailyTaskDate != today) {
      _dailyTaskDate = today;
      _mindSpaceDone = false;
      _chatDone = false;
    }
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

    // Save daily tasks
    final taskData =
        '${_dailyTaskDate ?? ''}|${_mindSpaceDone ? '1' : '0'}|${_chatDone ? '1' : '0'}';
    await prefs.setString(_dailyTasksKey, taskData);
  }
}
