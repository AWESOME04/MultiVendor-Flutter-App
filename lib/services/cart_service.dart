import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_service.dart';
import 'dart:async';

class CartService {
  static const String baseUrl = 'https://order-service-uag9.onrender.com';
  final UserService _userService;

  CartService(this._userService);

  Future<Map<String, dynamic>> addToCart({
    required String productId,
    required String name,
    required double price,
    required String image,
    int quantity = 1,
  }) async {
    try {
      final token = _userService.token;
      final userId = _userService.userId;

      if (token == null || userId == null) {
        throw 'User not authenticated';
      }

      final requestBody = {
        'productId': productId,
        'name': name,
        'price': price,
        'image': image,
        'quantity': quantity
      };

      print('Making request to: $baseUrl/cart');
      print('Request body: ${jsonEncode(requestBody)}');
      print('Token: $token');

      final response = await http
          .post(
        Uri.parse('$baseUrl/cart'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw 'Request timed out. The server might be starting up, please try again.';
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        try {
          final error = jsonDecode(response.body);
          throw error['message'] ?? 'Failed to add to cart';
        } catch (e) {
          if (response.statusCode == 403) {
            throw 'Authentication failed. Please log in again.';
          }
          throw 'Server error: ${response.statusCode}';
        }
      }
    } catch (e) {
      print('Error in addToCart: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCart() async {
    try {
      final token = _userService.token;
      if (token == null) {
        throw 'User not authenticated';
      }

      final response = await http.get(
        Uri.parse('$baseUrl/cart'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Get cart response: ${response.statusCode} - ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);

        if (data is Map) {
          if (data.containsKey('items')) {
            return {
              'items': (data['items'] as List?)?.map((item) {
                    if (item is Map) {
                      return {
                        'productId': item['productId']?.toString() ?? '',
                        'name': item['name']?.toString() ?? '',
                        'price': (item['price'] is num)
                            ? item['price'].toDouble()
                            : 0.0,
                        'quantity': (item['quantity'] is num)
                            ? item['quantity'].toInt()
                            : 1,
                        'image': item['image']?.toString() ?? '',
                      };
                    }
                    return item;
                  }).toList() ??
                  [],
              'total': (data['total'] is num) ? data['total'].toDouble() : 0.0,
            };
          } else {
            // Handle case where items might be the root object
            return {
              'items': [data]
                  .map((item) => {
                        'productId': item['productId']?.toString() ?? '',
                        'name': item['name']?.toString() ?? '',
                        'price': (item['price'] is num)
                            ? item['price'].toDouble()
                            : 0.0,
                        'quantity': (item['quantity'] is num)
                            ? item['quantity'].toInt()
                            : 1,
                        'image': item['image']?.toString() ?? '',
                      })
                  .toList(),
              'total': (data['price'] is num) ? data['price'].toDouble() : 0.0,
            };
          }
        }

        // If response is not a Map, return empty cart
        return {
          'items': [],
          'total': 0.0,
        };
      } else {
        final error = jsonDecode(response.body);
        throw error['message'] ?? 'Failed to get cart';
      }
    } catch (e) {
      print('Error getting cart: $e');
      if (e is http.ClientException) {
        throw 'Cannot connect to cart service. Please try again later.';
      }
      rethrow;
    }
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    try {
      final token = _userService.token;
      if (token == null) {
        throw 'User not authenticated';
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/cart/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'quantity': quantity}),
      );

      if (response.statusCode >= 400) {
        final error = jsonDecode(response.body);
        throw error['message'] ?? 'Failed to update quantity';
      }
    } catch (e) {
      print('Error updating quantity: $e');
      rethrow;
    }
  }

  Future<void> removeFromCart(String productId) async {
    try {
      final token = _userService.token;
      if (token == null) {
        throw 'User not authenticated';
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/cart/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode >= 400) {
        final error = jsonDecode(response.body);
        throw error['message'] ?? 'Failed to remove item';
      }
    } catch (e) {
      print('Error removing item: $e');
      rethrow;
    }
  }

  Future<void> checkout(String phone) async {
    try {
      final token = _userService.token;
      final userEmail = _userService.email;

      if (token == null) {
        throw 'User not authenticated';
      }

      // Get current cart data for email
      final cartData = await getCart();
      final items = cartData['items'] as List?;

      if (items == null || items.isEmpty) {
        throw 'Cart is empty';
      }

      // Send confirmation email first
      if (userEmail != null) {
        try {
          final emailResponse = await http.post(
            Uri.parse('$baseUrl/send-order-email'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'email': userEmail,
              'orderDetails': _generateOrderEmailHtml(
                items,
                cartData['total'] ?? 0,
                phone,
              ),
            }),
          );
          print(
              'Email response: ${emailResponse.statusCode} - ${emailResponse.body}');
        } catch (e) {
          print('Error sending confirmation email: $e');
          // Continue even if email fails
        }
      }

      // Clear the cart
      await http.delete(
        Uri.parse('$baseUrl/cart'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      print('Error during checkout: $e');
      rethrow;
    }
  }

  String _generateOrderEmailHtml(List items, double total, String phone) {
    return '''
      <h2>Order Confirmation</h2>
      <p>Thank you for your order!</p>
      <h3>Order Details:</h3>
      <ul>
      ${items.map((item) => '''
        <li>
          ${item['name']} - Quantity: ${item['quantity']} - \$${(item['price'] * (item['quantity'] ?? 1)).toStringAsFixed(2)}
        </li>
      ''').join('')}
      </ul>
      <p><strong>Total: \$${total.toStringAsFixed(2)}</strong></p>
      <p>Phone: $phone</p>
      <p>We'll contact you shortly to confirm your order.</p>
    ''';
  }
}
