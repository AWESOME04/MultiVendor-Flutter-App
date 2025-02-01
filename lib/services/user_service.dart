import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService extends ChangeNotifier {
  String? _token;
  String? _userId;
  String? _userRole;
  bool _isAuthenticated = false;
  bool _initialized = false;

  bool get isInitialized => _initialized;
  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  String? get userId => _userId;
  String? get userRole => _userRole;

  Future<void> initializeFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      _userId = prefs.getString('userId');
      _userRole = prefs.getString('userRole');
      _isAuthenticated = _token != null;
      _initialized = true;
      notifyListeners();
    } catch (e) {
      print('Error initializing from storage: $e');
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> setUserData({
    required String token,
    required String userId,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Store in memory
    _token = token;
    _userId = userId;
    _userRole = role;
    _isAuthenticated = true;

    // Store in persistent storage
    await prefs.setString('token', token);
    await prefs.setString('userId', userId);
    await prefs.setString('userRole', role);

    notifyListeners();
  }

  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();

    // Clear memory
    _token = null;
    _userId = null;
    _userRole = null;
    _isAuthenticated = false;

    // Clear storage
    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('userRole');

    notifyListeners();
  }

  bool get isSeller => _userRole == 'SELLER';
  bool get isBuyer => _userRole == 'BUYER';
}
