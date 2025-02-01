import 'dart:convert';
import 'package:http/http.dart' as http;

class Product {
  final int id;
  final String name;
  final String desc;
  final String img;
  final String type;
  final int stock;
  final double price;
  final bool available;
  final int seller;

  Product({
    required this.id,
    required this.name,
    required this.desc,
    required this.img,
    required this.type,
    required this.stock,
    required this.price,
    required this.available,
    required this.seller,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Handle price conversion from string to double
    double parsePrice(dynamic price) {
      if (price is String) {
        return double.tryParse(price) ?? 0.0;
      } else if (price is num) {
        return price.toDouble();
      }
      return 0.0;
    }

    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      desc: json['desc'] ?? '',
      img: json['img'] ?? 'https://placehold.co/600x400',
      type: json['type'] ?? '',
      stock: json['stock'] ?? 0,
      price: parsePrice(json['price']),
      available: json['available'] ?? false,
      seller: json['seller'] ?? 0,
    );
  }
}

class ProductService {
  static const String baseUrl = 'https://product-service-qwti.onrender.com';

  Future<List<Product>> getProducts() async {
    try {
      print('Fetching products from $baseUrl');
      final response = await http.get(Uri.parse('$baseUrl/'));
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('products')) {
          final List<dynamic> products = data['products'];
          return products.map((json) => Product.fromJson(json)).toList();
        } else {
          throw Exception('Invalid response format: missing products key');
        }
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching products: $e');
      throw Exception('Failed to connect to the server: $e');
    }
  }
}
