import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class baseurls {
  static const String mainurl = 'https://alhad.pythonanywhere.com/';
}

class ApiService {
  static int min(int a, int b) => a < b ? a : b;
  static const String baseUrl = baseurls.mainurl;

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
      final token = prefs.getString('auth_token');
      return token;
    } catch (e) {
      developer.log('Error retrieving token: $e');
      return null;
    }
  }

  // Save token to local storage
  static Future<void> _saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      developer.log('Token saved successfully');
    } catch (e) {
      developer.log('Error saving token: $e');
    }
  }

  // Remove token from local storage
  static Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    developer.log('Token removed');
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

  static Future<bool> isLoggedIn() async {
    final token = await _getToken();
    return token != null && token.isNotEmpty;
  }

  // 1. User Signup
  static Future<Map<String, dynamic>> signup({
    required String username,
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/users/signup/'),
      headers: await _getHeaders(),
      body: json.encode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    final data = _handleResponse(response);
    if (data['token'] != null) {
      await _saveToken(data['token']);
    }
    return data;
  }

  // 2. User Login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/users/login/'),
      headers: await _getHeaders(),
      body: json.encode({'email': email, 'password': password}),
    );

    final data = _handleResponse(response);
    if (data['token'] != null) {
      await _saveToken(data['token']);
    }
    return data;
  }

  // 3. User Logout
  static Future<Map<String, dynamic>> logout() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/users/logout/'),
      headers: await _getHeaders(),
    );

    final data = _handleResponse(response);
    await _removeToken();
    return data;
  }

  // 4. Get All Products
  // 4. Get All Products
  // static Future<Map<String, dynamic>> getProducts({
  //   String? categoryId,
  //   String? search,
  //   int page = 1,
  //   int pageSize = 10,
  // }) async {
  //   final queryParams = {
  //     if (categoryId != null) 'category_id': categoryId,
  //     if (search != null) 'search': search,
  //     'page': page.toString(),
  //     'page_size': pageSize.toString(),
  //   };

  //   final uri = Uri.parse(
  //     '$baseUrl/api/products/',
  //   ).replace(queryParameters: queryParams);
  //   final response = await http.get(uri, headers: await _getHeaders());

  //   final responseData = _handleResponse(response);

  //   // Handle different response formats
  //   if (responseData is List) {
  //     // Convert list to map format for consistency
  //     return {'results': responseData};
  //   } else if (responseData is Map<String, dynamic>) {
  //     return responseData;
  //   } else {
  //     return {'results': []};
  //   }
  // }

  static Future<Map<String, dynamic>> getProducts({
    String? categoryId,
    String? restaurantId, // Add this parameter
    String? search,
    int page = 1,
    int pageSize = 10,
  }) async {
    final queryParams = {
      if (categoryId != null) 'category_id': categoryId,
      if (restaurantId != null)
        'restaurant_id': restaurantId, // Add this condition
      if (search != null) 'search': search,
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };

    final uri = Uri.parse(
      '$baseUrl/api/products/',
    ).replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: await _getHeaders());

    final responseData = _handleResponse(response);

    // Handle different response formats
    if (responseData is List) {
      // Convert list to map format for consistency
      return {'results': responseData};
    } else if (responseData is Map<String, dynamic>) {
      return responseData;
    } else {
      return {'results': []};
    }
  }

  // 5. Get Restaurant Products
  // Update this method in ApiService
  static Future<Map<String, dynamic>> getRestaurantProducts(
    int? restaurantId, {
    int page = 1,
    int pageSize = 10,
  }) async {
    final queryParams = {
      'restaurant_id':
          restaurantId?.toString() ??
          '', // Add restaurant_id as query parameter
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };

    // Use the products endpoint with restaurant_id as a query parameter
    final uri = Uri.parse(
      '$baseUrl/api/products/',
    ).replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri, headers: await _getHeaders());

      // Parse the response
      final dynamic parsedResponse = _handleResponse(response);

      // Handle different response formats
      if (parsedResponse is Map<String, dynamic>) {
        return parsedResponse;
      } else if (parsedResponse is List) {
        return {'results': parsedResponse};
      } else {
        return {'results': []};
      }
    } catch (e) {
      print('Error loading restaurant products: $e');
      throw e;
    }
  }

  static Future<List<dynamic>> getRestaurants() async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/restaurant/',
      ), // Note: 'restaurant' not 'restaurants'
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  // 6. Get Categories
  static Future<List<dynamic>> getCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/categories/'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  // 7. Get Cart
  static Future<Map<String, dynamic>> getCart() async {
    try {
      final headers = await _getHeaders();
      developer.log('Fetching cart with headers: $headers');

      final response = await http.get(
        Uri.parse('$baseUrl/api/cart/'),
        headers: headers,
      );

      return _handleResponse(response);
    } catch (e) {
      developer.log('Error in getCart: $e');
      rethrow;
    }
  }

  // 8. Add to Cart
  static Future<Map<String, dynamic>> addToCart({
    required int productId,
    required int quantity,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/cart/add/'),
      headers: await _getHeaders(),
      body: json.encode({
        'product_id': productId,
        'quantity': quantity,
        if (notes != null) 'notes': notes,
      }),
    );

    return _handleResponse(response);
  }

  // 9. Update Cart Item
  static Future<Map<String, dynamic>> updateCartItem({
    required int itemId,
    required int quantity,
    String? notes,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/cart/update/$itemId/'),
      headers: await _getHeaders(),
      body: json.encode({
        'quantity': quantity,
        if (notes != null) 'notes': notes,
      }),
    );

    return _handleResponse(response);
  }

  // 10. Remove from Cart
  static Future<Map<String, dynamic>> removeFromCart(int itemId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/cart/remove/$itemId/'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  // 11. Checkout
  // Update the ApiService checkout method
  static Future<dynamic> checkout({
    required String address,
    required String phoneNumber,
    required double latitude,
    required double longitude,
    String paymentMethod = 'cash_on_delivery',
    String? notes,
  }) async {
    try {
      // Make sure we have a token
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        developer.log('No auth token available for checkout');
        throw Exception('Authentication required. Please log in first.');
      }

      final headers = await _getHeaders();
      developer.log('Using headers for checkout: $headers');

      final requestBody = {
        'address': address,
        'phone': phoneNumber,
        'latitude': latitude,
        'longitude': longitude,
        'payment_method': paymentMethod,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      developer.log('Checkout request body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/api/checkout/'),
        headers: headers,
        body: json.encode(requestBody),
      );

      developer.log('Checkout response: ${response.statusCode}');
      developer.log('Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          return json.decode(response.body);
        } catch (e) {
          developer.log('Failed to parse JSON response: $e');
          // Return success even if parsing fails
          return {'success': true, 'message': 'Order placed successfully'};
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log('Checkout error: $e');
      throw Exception('Failed to process checkout: $e');
    }
  }

  // Also update the _handleResponse method to be more flexible with return types

  // 12. Get Orders
  static Future<List<dynamic>> getOrders({
    String? status,
    int page = 1,
    int pageSize = 10,
  }) async {
    final queryParams = {
      if (status != null) 'status': status,
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };

    final uri = Uri.parse(
      '$baseUrl/api/orders/',
    ).replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: await _getHeaders());

    return _handleResponse(response);
  }

  // 13. Get Order Details
  static Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/orders/$orderId/'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }
}
