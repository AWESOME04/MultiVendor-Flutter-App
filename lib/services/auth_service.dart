import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/user_service.dart';

class AuthService {
  static const String baseUrl = 'https://auth-service-rbc3.onrender.com';

  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String phone,
    String role = 'BUYER',
  }) async {
    try {
      print('Attempting signup to: $baseUrl/signup');

      final response = await http.post(
        Uri.parse('$baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'phone': phone,
          'role': role.toUpperCase(), // Ensure role is uppercase
        }),
      );

      print('Signup response: ${response.statusCode} - ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);

        // Create a complete user data object
        final userData = {
          'token': data['token'] ?? '',
          'id': data['id']?.toString() ?? '',
          'role':
              (data['role'] as String?)?.toUpperCase() ?? role.toUpperCase(),
          'email': email,
        };

        await handleAuthResponse(userData, UserService());
        return userData;
      } else {
        final error = jsonDecode(response.body);
        throw error['message'] ?? 'Sign up failed';
      }
    } catch (e) {
      print('Signup error details: $e');
      if (e.toString().contains('<!DOCTYPE')) {
        throw 'Server error. Please try again later.';
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('Attempting login to: $baseUrl/login');

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Login response: ${response.statusCode} - ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);

        // Ensure role is uppercase for consistency
        final role = (data['role'] as String?)?.toUpperCase() ?? 'BUYER';

        await handleAuthResponse({
          ...data,
          'role': role,
        }, UserService());

        return data;
      } else {
        final error = jsonDecode(response.body);
        throw error['message'] ?? 'Failed to login';
      }
    } catch (e) {
      print('Login error details: $e');
      if (e.toString().contains('<!DOCTYPE')) {
        throw 'Server error. Please try again later.';
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final data = jsonDecode(response.body);
        throw data['message'] ?? 'Failed to get profile';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String name,
    required String gender,
    required String street,
    required String postalCode,
    required String city,
    required String country,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'gender': gender,
          'street': street,
          'postalCode': postalCode,
          'city': city,
          'country': country,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final data = jsonDecode(response.body);
        throw data['message'] ?? 'Failed to update profile';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> handleAuthResponse(
      Map<String, dynamic> data, UserService userService) async {
    await userService.setUserData(
      token: data['token'],
      userId: data['id'].toString(),
      role: data['role'].toString().toUpperCase(),
      email: data['email']?.toString(),
    );
  }
}
