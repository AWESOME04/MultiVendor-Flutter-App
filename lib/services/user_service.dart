import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserService extends ChangeNotifier {
  static const String baseUrl = 'https://auth-service-rbc3.onrender.com';

  String? _token;
  String? _userId;
  String? _userRole;
  String? _email;
  bool _isAuthenticated = false;
  bool _initialized = false;

  // Required getters for other services
  bool get isInitialized => _initialized;
  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  String? get userId => _userId;
  String? get userRole => _userRole;
  String? get email => _email;

  // Role-specific getters
  String get normalizedRole => _userRole?.toUpperCase() ?? '';
  bool get isSeller => normalizedRole == 'SELLER';
  bool get isBuyer => normalizedRole == 'BUYER';

  Future<void> initializeFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get all data at once
      _token = prefs.getString('token');
      _userId = prefs.getString('userId');
      _userRole = prefs.getString('userRole')?.toUpperCase(); // Normalize role
      _email = prefs.getString('email');

      // Update authentication state
      _isAuthenticated = _token != null && _userId != null && _userRole != null;
      _initialized = true;

      // Force UI update
      notifyListeners();

      // If we have a token but missing other data, try to fetch profile
      if (_token != null && (_userId == null || _userRole == null)) {
        await refreshUserData();
      }
    } catch (e) {
      print('Error initializing from storage: $e');
      _initialized = true;
      notifyListeners();
    }
  }

  // Add method to refresh user data
  Future<void> refreshUserData() async {
    try {
      if (_token == null) return;

      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);

        // Update user data
        await setUserData(
          token: _token!,
          userId: data['id']?.toString() ?? _userId ?? '',
          role:
              (data['role'] as String?)?.toUpperCase() ?? _userRole ?? 'BUYER',
          email: data['email'] ?? _email,
        );
      }
    } catch (e) {
      print('Error refreshing user data: $e');
    }
  }

  Future<void> setUserData({
    required String token,
    required String userId,
    required String role,
    String? email,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Normalize and validate data
    final normalizedRole = role.toUpperCase();
    if (normalizedRole.isEmpty || userId.isEmpty || token.isEmpty) {
      throw 'Invalid user data provided';
    }

    // Update memory
    _token = token;
    _userId = userId;
    _userRole = normalizedRole;
    _email = email;
    _isAuthenticated = true;
    _initialized = true;

    // Notify immediately
    notifyListeners();

    // Update storage
    await prefs.setString('token', token);
    await prefs.setString('userId', userId);
    await prefs.setString('userRole', normalizedRole);
    if (email != null) {
      await prefs.setString('email', email);
    }

    // Notify again after storage update
    notifyListeners();
  }

  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();

    // Clear memory
    _token = null;
    _userId = null;
    _userRole = null;
    _email = null;
    _isAuthenticated = false;

    // Clear storage
    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('userRole');
    await prefs.remove('email');

    notifyListeners();
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    if (!isAuthenticated) {
      throw 'User not authenticated';
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw 'Failed to get user profile';
      }
    } catch (e) {
      print('Error getting user profile: $e');
      rethrow;
    }
  }
}
