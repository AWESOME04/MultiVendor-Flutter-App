import 'package:flutter/foundation.dart';

class CartNotifier extends ChangeNotifier {
  int _cartItemCount = 0;

  int get cartItemCount => _cartItemCount;

  void updateCount(int count) {
    _cartItemCount = count;
    notifyListeners();
  }
}
