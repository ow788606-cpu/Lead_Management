import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_config.dart';

class AuthManager {
  static final AuthManager _instance = AuthManager._internal();
  factory AuthManager() => _instance;
  AuthManager._internal();

  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _usernameKey = 'username';
  static const String _userIdKey = 'userId';

  Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, value);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.remove(_usernameKey);
    await prefs.remove(_userIdKey);
  }

  Future<void> setUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  Future<void> setUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': identifier.trim(),
          'password': password,
        }),
      );

      if (response.statusCode != 200) {
        return false;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return false;
      }

      if (decoded['success'] != true) {
        return false;
      }

      final data = decoded['data'];
      if (data is! Map<String, dynamic>) {
        return false;
      }

      final username = (data['username'] ?? '').toString();
      final userId = int.tryParse((data['user_id'] ?? '').toString());
      if (userId == null || userId <= 0) {
        return false;
      }
      await setUserId(userId);
      await setUsername(username);
      await setLoggedIn(true);
      return true;
    } catch (_) {
      return false;
    }
  }
}
