import 'package:flutter/material.dart';
import 'package:flutter_paystack_plus/flutter_paystack_plus.dart';

class PaystackService {
  static const String publicKey =
      'pk_test_1159077c47e09194898ceeee3cf3909fc969ec7b';
  static const String secretKey =
      'sk_test_7b20a436a5b91b761607a9a9b16d2a49b486768e';

  static Future<bool> processPayment({
    required BuildContext context,
    required String email,
    required double amount,
    required String phone,
    required VoidCallback onSuccess,
    required VoidCallback onCancel,
  }) async {
    try {
      final ref = 'ref_${DateTime.now().millisecondsSinceEpoch}';

      await FlutterPaystackPlus.openPaystackPopup(
        publicKey: publicKey,
        secretKey: secretKey,
        context: context,
        amount: (amount * 100).toString(),
        currency: 'GHS',
        customerEmail: email,
        reference: ref,
        callBackUrl: "https://multi-vendor-system.vercel.app",
        onClosed: () {
          onCancel();
          debugPrint('Payment cancelled');
        },
        onSuccess: () {
          onSuccess();
          debugPrint('Payment successful');
        },
        metadata: {
          'phone': phone,
        },
      );

      return true;
    } catch (e) {
      debugPrint('Payment error: $e');
      return false;
    }
  }
}
