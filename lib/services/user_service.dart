import 'package:flutter/foundation.dart';

class UserService extends ChangeNotifier {
  String? _userType;
  String? _token;

  String? get userType => _userType;
  String? get token => _token;

  void setUserData(String userType, String token) {
    _userType = userType;
    _token = token;
    notifyListeners();
  }

  void clearUserData() {
    _userType = null;
    _token = null;
    notifyListeners();
  }

  bool get isSeller => _userType == 'SELLER';
  bool get isBuyer => _userType == 'BUYER';
}
