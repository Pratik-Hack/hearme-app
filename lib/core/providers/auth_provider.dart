import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:hearme/models/user_model.dart';
import 'package:hearme/services/auth_service.dart';
import 'package:hearme/services/api_service.dart';
import 'package:hearme/core/constants/api_constants.dart';

class AuthProvider extends ChangeNotifier {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  String? _token;
  UserModel? _user;
  bool _isLoading = false;
  bool _initialized = false;
  String? _error;

  String? get token => _token;
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get initialized => _initialized;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _user != null;
  bool get isPatient => _user?.isPatient ?? false;
  bool get isDoctor => _user?.isDoctor ?? false;

  /// Call this once at app startup (from splash screen).
  /// Returns true if a valid session was restored.
  Future<bool> tryRestoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);

    if (token != null && userJson != null) {
      if (JwtDecoder.isExpired(token)) {
        await _clearStorage();
        _initialized = true;
        notifyListeners();
        return false;
      }
      _token = token;
      _user = UserModel.fromJson(jsonDecode(userJson));
      ApiService.setToken(_token);
      _initialized = true;
      notifyListeners();
      return true;
    }

    _initialized = true;
    notifyListeners();
    return false;
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await AuthService.login(email, password);
      _token = result['token'];
      _user = UserModel.fromJson(result['user']);
      ApiService.setToken(_token);
      await _saveToStorage();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await AuthService.register(data);
      _token = result['token'];
      _user = UserModel.fromJson(result['user']);
      ApiService.setToken(_token);
      await _saveToStorage();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshUser() async {
    try {
      final data = await ApiService.get(ApiConstants.profile);
      _user = UserModel.fromJson(data);
      await _saveToStorage();
      notifyListeners();
    } catch (_) {
      // Silently fail — keep existing user data
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    _error = null;
    ApiService.setToken(null);
    await _clearStorage();
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) await prefs.setString(_tokenKey, _token!);
    if (_user != null) {
      await prefs.setString(_userKey, jsonEncode(_user!.toJson()));
    }
  }

  Future<void> _clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
