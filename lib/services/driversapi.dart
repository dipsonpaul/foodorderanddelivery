import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';

class DeliveryApiService {
  static int min(int a, int b) => a < b ? a : b;
  static const String baseUrl = 'https://alhad.pythonanywhere.com/';

  // Headers
  static Future<Map<String, String>> _getHeaders() async {
    Map<String, String> headers = {'Content-Type': 'application/json'};
    String? token = await _getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Token $token';
      developer.log(
        'Token included in request: ${token.substring(0, min(10, token.length))}...',
      );
    } else {
      developer.log('No token available for API request');
    }
    return headers;
  }

  // Get token from local storage
  static Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      return token;
    } catch (e) {
      developer.log('Error retrieving token: $e');
      return null;
    }
  }

  // Save token and user info to local storage
  static Future<void> saveDeliveryUserData({
    required String token,
    required String username,
    required String email,
    int? userId,
    bool? isDeliveryBoy,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('username', username);
      await prefs.setString('email', email);

      if (userId != null) {
        await prefs.setInt('user_id', userId);
      }

      if (isDeliveryBoy != null) {
        await prefs.setBool('delivery_boy', isDeliveryBoy);
      }

      developer.log('Delivery user data saved successfully');
    } catch (e) {
      developer.log('Error saving delivery user data: $e');
      throw Exception('Failed to save user data: $e');
    }
  }

  // Clear all user data on logout
  static Future<void> clearDeliveryUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      developer.log('Delivery user data cleared');
    } catch (e) {
      developer.log('Error clearing delivery user data: $e');
      throw Exception('Failed to clear user data: $e');
    }
  }

  // Error handling
  static dynamic _handleResponse(http.Response response) {
    developer.log('API Response - Status Code: ${response.statusCode}');
    developer.log(
      'Response body: ${response.body.substring(0, min(200, response.body.length))}...',
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      developer.log('Authentication failed - 401 Unauthorized');
      throw Exception('Authentication failed. Please login again.');
    } else {
      developer.log('API Error: ${response.statusCode} - ${response.body}');
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }

  // Check if delivery person is logged in
  static Future<bool> isDeliveryPersonLoggedIn() async {
    final token = await _getToken();
    return token != null && token.isNotEmpty;
  }

  // Delivery Person Login
  static Future<Map<String, dynamic>> deliveryLogin({
    required String email,
    required String password,
    BuildContext? context,
    Function(String)? onError,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/login/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final data = _handleResponse(response);

      // Check if the user is a delivery boy
      if (data['delivery_boy'] == true) {
        await saveDeliveryUserData(
          token: data['token'],
          username: data['username'] ?? '',
          email: data['email'] ?? '',
          userId: data['user_id'],
          isDeliveryBoy: data['delivery_boy'],
        );
        return data;
      } else {
        final errorMsg = 'Access denied. Only delivery personnel can login.';
        if (onError != null) {
          onError(errorMsg);
        }
        throw Exception(errorMsg);
      }
    } catch (e) {
      developer.log('Delivery login error: $e');
      if (onError != null) {
        onError(e.toString());
      }
      throw Exception('Failed to login: $e');
    }
  }

  // Get Assigned Orders (Both Pending and Delivered)
  static Future<Map<String, dynamic>> getAssignedOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/orders/assigned/'),
        headers: await _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      developer.log('Error fetching assigned orders: $e');
      throw Exception('Failed to fetch assigned orders: $e');
    }
  }

  // Update Order Status (Mark as Delivered)
  static Future<Map<String, dynamic>> updateOrderStatus(
    int orderId,
    String status,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/orders/$orderId/update_status_d/'),
        headers: await _getHeaders(),
        body: json.encode({"status": status}),
      );

      return _handleResponse(response);
    } catch (e) {
      developer.log('Error updating order status: $e');
      throw Exception('Failed to update order status: $e');
    }
  }

  // Get Delivery Person Profile
  static Future<Map<String, dynamic>> getDeliveryProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/delivery/profile/'),
        headers: await _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      developer.log('Error fetching delivery profile: $e');
      throw Exception('Failed to fetch profile: $e');
    }
  }

  // Get Delivery Statistics (like total deliveries, etc.)
  static Future<Map<String, dynamic>> getDeliveryStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/delivery/stats/'),
        headers: await _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      developer.log('Error fetching delivery stats: $e');
      throw Exception('Failed to fetch delivery statistics: $e');
    }
  }

  // Load User Data from SharedPreferences
  static Future<Map<String, dynamic>> loadDeliveryUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'username': prefs.getString('username'),
        'email': prefs.getString('email'),
        'token': prefs.getString('token'),
        'user_id': prefs.getInt('user_id'),
        'delivery_boy': prefs.getBool('delivery_boy'),
      };
    } catch (e) {
      developer.log('Error loading delivery user data: $e');
      throw Exception('Failed to load user data: $e');
    }
  }
}
