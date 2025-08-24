import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/hotel.dart';
import '../models/booking.dart';
import '../models/payment.dart';
import '../models/review.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';

class ApiService {
  // Use different URLs based on platform and debug mode
  static String get baseUrl {
    String url;
    if (kDebugMode) {
      // In debug mode, use appropriate URLs for different platforms
      if (Platform.isAndroid) {
        // Android emulator uses 10.0.2.2 to access host machine's localhost
        url = 'http://10.0.2.2:8000/api';
      } else if (Platform.isIOS) {
        // iOS simulator can use localhost directly
        url = 'http://localhost:8000/api';
      } else {
        // For other platforms (Windows, macOS, Linux)
        url = 'http://localhost:8000/api';
      }
    } else {
      // In release mode, use your production API URL
      url = 'https://your-production-api.com/api';
    }
    
    print('ApiService: Using base URL: $url');
    print('ApiService: Platform: ${Platform.operatingSystem}, Debug: $kDebugMode');
    return url;
  }
  String? _token;
  Function()? _onTokenExpired;

  void setToken(String? token) {
    _token = token;
  }

  void setTokenExpiredCallback(Function() callback) {
    _onTokenExpired = callback;
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
    
    // Reduced logging for performance
    if (_token == null && kDebugMode) {
      print('No token available');
    }
    
    return headers;
  }

  Future<http.Response> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: queryParams,
    );

    print('API Request: $method $uri');
    if (body != null) {
      print('Request body: ${jsonEncode(body)}');
    }

    http.Response response;
    try {
      switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(uri, headers: _headers);
        break;
      case 'POST':
        response = await http.post(
          uri,
          headers: _headers,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'PUT':
        response = await http.put(
          uri,
          headers: _headers,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: _headers);
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
      }
    } catch (e) {
      print('Network error: $e');
      if (e.toString().contains('SocketException')) {
        throw Exception('Cannot connect to server. Please check if the backend is running on the correct address.');
      }
      rethrow;
    }

    print('API Response: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode >= 400) {
      print('API Error: Status ${response.statusCode}');
      print('API Error: Body ${response.body}');
      
      // Handle token expiration (401 Unauthorized)
      if (response.statusCode == 401) {
        print('Token expired, triggering logout');
        _onTokenExpired?.call();
      }
      
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Request failed');
      } catch (e) {
        throw Exception('Request failed with status ${response.statusCode}: ${response.body}');
      }
    }

    return response;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _makeRequest('POST', '/auth/login', body: {
      'email': email,
      'password': password,
    });
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final response =
        await _makeRequest('POST', '/auth/register', body: userData);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> googleLogin(String idToken) async {
    final response = await _makeRequest('POST', '/auth/google', body: {
      'id_token': idToken,
    });
    return jsonDecode(response.body);
  }

  Future<User> getCurrentUser() async {
    final response = await _makeRequest('GET', '/users/me');
    return User.fromJson(jsonDecode(response.body));
  }

  Future<User> updateUser(Map<String, dynamic> userData) async {
    final response = await _makeRequest('PUT', '/users/me', body: userData);
    return User.fromJson(jsonDecode(response.body));
  }

  Future<List<Hotel>> getHotels({
    int skip = 0,
    int limit = 100,
    String? city,
    double? minPrice,
    double? maxPrice,
    String? amenities,
    bool amenitiesMatchAll = false,
  }) async {
    final queryParams = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
      if (city != null) 'city': city,
      if (minPrice != null) 'min_price': minPrice.toString(),
      if (maxPrice != null) 'max_price': maxPrice.toString(),
      if (amenities != null) 'amenities': amenities,
      'amenities_match_all': amenitiesMatchAll.toString(),
    };

    final response =
        await _makeRequest('GET', '/hotels', queryParams: queryParams);
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Hotel.fromJson(json)).toList();
  }

  Future<List<Hotel>> searchHotels(String query) async {
    final response = await _makeRequest('GET', '/hotels/search', queryParams: {
      'q': query,
    });
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Hotel.fromJson(json)).toList();
  }

  Future<Hotel> getHotel(int id) async {
    final response = await _makeRequest('GET', '/hotels/$id');
    return Hotel.fromJson(jsonDecode(response.body));
  }

  Future<Hotel> createHotel(Map<String, dynamic> hotelData) async {
    final response = await _makeRequest('POST', '/hotels/', body: hotelData);
    return Hotel.fromJson(jsonDecode(response.body));
  }

  Future<Hotel> updateHotel(int id, Map<String, dynamic> hotelData) async {
    final response = await _makeRequest('PUT', '/hotels/$id', body: hotelData);
    return Hotel.fromJson(jsonDecode(response.body));
  }

  Future<void> deleteHotel(int id) async {
    await _makeRequest('DELETE', '/hotels/$id');
  }

  Future<List<Hotel>> getOwnerHotels() async {
    final response = await _makeRequest('GET', '/hotels/owner/my-hotels');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Hotel.fromJson(json)).toList();
  }

  Future<List<Booking>> getUserBookings() async {
    final response = await _makeRequest('GET', '/bookings');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Booking.fromJson(json)).toList();
  }

  Future<Booking> getBooking(int id) async {
    final response = await _makeRequest('GET', '/bookings/$id');
    return Booking.fromJson(jsonDecode(response.body));
  }

  Future<Booking> createBooking(Map<String, dynamic> bookingData) async {
    final response = await _makeRequest('POST', '/bookings/', body: bookingData);
    return Booking.fromJson(jsonDecode(response.body));
  }

  Future<Booking> updateBooking(
      int id, Map<String, dynamic> bookingData) async {
    final response =
        await _makeRequest('PUT', '/bookings/$id', body: bookingData);
    return Booking.fromJson(jsonDecode(response.body));
  }

  Future<void> cancelBooking(int id) async {
    await _makeRequest('DELETE', '/bookings/$id');
  }

  Future<List<Booking>> getHotelBookings() async {
    final response =
        await _makeRequest('GET', '/bookings/owner/hotel-bookings');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Booking.fromJson(json)).toList();
  }

  Future<void> confirmBooking(int id) async {
    await _makeRequest('PUT', '/bookings/$id/confirm');
  }

  Future<void> rejectBooking(int id) async {
    await _makeRequest('PUT', '/bookings/$id/reject');
  }

  Future<void> checkInBooking(int id) async {
    await _makeRequest('PUT', '/bookings/$id/check-in');
  }

  Future<void> checkOutBooking(int id) async {
    await _makeRequest('PUT', '/bookings/$id/check-out');
  }

  Future<void> selfCheckInBooking(int id) async {
    await _makeRequest('PUT', '/bookings/$id/self-checkin');
  }

  Future<void> selfCheckOutBooking(int id) async {
    await _makeRequest('PUT', '/bookings/$id/self-checkout');
  }

  Future<Map<String, dynamic>> qrCheckInBooking(String qrCode) async {
    final response = await _makeRequest('PUT', '/bookings/qr-checkin/$qrCode');
    return jsonDecode(response.body);
  }

  Future<List<PaymentMethod>> getPaymentMethods() async {
    final response = await _makeRequest('GET', '/payments/methods');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => PaymentMethod.fromJson(json)).toList();
  }

  Future<PaymentMethod> addPaymentMethod(
      Map<String, dynamic> paymentData) async {
    final response =
        await _makeRequest('POST', '/payments/methods', body: paymentData);
    return PaymentMethod.fromJson(jsonDecode(response.body));
  }

  Future<PaymentMethod> updatePaymentMethod(
      int id, Map<String, dynamic> paymentData) async {
    final response =
        await _makeRequest('PUT', '/payments/methods/$id', body: paymentData);
    return PaymentMethod.fromJson(jsonDecode(response.body));
  }

  Future<void> deletePaymentMethod(int id) async {
    await _makeRequest('DELETE', '/payments/methods/$id');
  }

  Future<Payment> processPayment(Map<String, dynamic> paymentData) async {
    final response =
        await _makeRequest('POST', '/payments/process', body: paymentData);
    return Payment.fromJson(jsonDecode(response.body));
  }

  Future<List<Payment>> getUserPayments() async {
    final response = await _makeRequest('GET', '/payments');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Payment.fromJson(json)).toList();
  }

  Future<List<Review>> getHotelReviews(int hotelId) async {
    final response = await _makeRequest('GET', '/reviews/hotel/$hotelId');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Review.fromJson(json)).toList();
  }

  Future<Review> createReview(Map<String, dynamic> reviewData) async {
    final response = await _makeRequest('POST', '/reviews/', body: reviewData);
    return Review.fromJson(jsonDecode(response.body));
  }

  Future<Review> updateReview(int id, Map<String, dynamic> reviewData) async {
    final response =
        await _makeRequest('PUT', '/reviews/$id', body: reviewData);
    return Review.fromJson(jsonDecode(response.body));
  }

  Future<Review> replyToReview(int id, String reply) async {
    final response = await _makeRequest('PUT', '/reviews/$id/reply', body: {
      'owner_reply': reply,
    });
    return Review.fromJson(jsonDecode(response.body));
  }

  Future<void> deleteReview(int id) async {
    await _makeRequest('DELETE', '/reviews/$id');
  }

  Future<List<Review>> getUserReviews() async {
    final response = await _makeRequest('GET', '/reviews/user/my-reviews');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Review.fromJson(json)).toList();
  }

  Future<List<ChatMessage>> getChatMessages(int hotelId) async {
    final response = await _makeRequest('GET', '/chat/hotel/$hotelId');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => ChatMessage.fromJson(json)).toList();
  }

  Future<ChatMessage> sendMessage(int hotelId, String message) async {
    print('API Service: Sending message to hotel $hotelId: $message');
    print('API Service: Token available: ${_token != null}');
    print('API Service: Base URL: $baseUrl');
    
    final response = await _makeRequest('POST', '/chat/hotel/$hotelId', body: {
      'message': message,
    });
    
    print('API Service: Response status: ${response.statusCode}');
    print('API Service: Response body: ${response.body}');
    
    return ChatMessage.fromJson(jsonDecode(response.body));
  }

  Future<ChatMessage> ownerReply(int hotelId, String message) async {
    final response =
        await _makeRequest('POST', '/chat/hotel/$hotelId/owner-reply', body: {
      'message': message,
    });
    return ChatMessage.fromJson(jsonDecode(response.body));
  }

  Future<void> deleteMessage(int messageId) async {
    await _makeRequest('DELETE', '/chat/message/$messageId');
  }

  Future<List<ChatConversation>> getOwnerConversations() async {
    final response = await _makeRequest('GET', '/chat/owner/conversations');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => ChatConversation.fromJson(json)).toList();
  }

  Future<List<ChatMessage>> getChatMessagesForOwner({
    required int hotelId,
    required int userId,
  }) async {
    final response =
        await _makeRequest('GET', '/chat/owner/chats/$hotelId/$userId');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => ChatMessage.fromJson(json)).toList();
  }

  Future<ChatMessage> sendOwnerMessage({
    required int hotelId,
    required int userId,
    required String message,
    required bool isFromOwner,
  }) async {
    final response =
        await _makeRequest('POST', '/chat/owner/chats/$hotelId/$userId', body: {
      'message': message,
    });
    return ChatMessage.fromJson(jsonDecode(response.body));
  }

  Future<void> markMessagesAsRead({
    required int hotelId,
    int? userId,
  }) async {
    try {
      await _makeRequest('POST', '/chat/mark-read', body: {
        'hotel_id': hotelId,
        if (userId != null) 'user_id': userId,
      });
    } catch (e) {
      print('Failed to mark messages as read: $e');
    }
  }

  Future<String> uploadHotelImage(File imageFile) async {
    var request = http.MultipartRequest(
      'POST', 
      Uri.parse('$baseUrl/hotels/upload-image')
    );
    
    // Add authorization header
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    
    // Add the file
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path)
    );
    
    var response = await request.send();
    
    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      var jsonData = jsonDecode(responseData);
      return jsonData['image_url'];
    } else {
      throw Exception('Failed to upload image: ${response.statusCode}');
    }
  }

  Future<List<String>> uploadHotelImages(List<File> imageFiles) async {
    // Client-side validation
    if (imageFiles.length > 10) {
      throw Exception('Maximum 10 images allowed. Please select fewer images.');
    }
    
    if (imageFiles.isEmpty) {
      throw Exception('At least one image is required');
    }
    
    var request = http.MultipartRequest(
      'POST', 
      Uri.parse('$baseUrl/hotels/upload-images')
    );
    
    // Add authorization header
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    
    // Add all files
    for (var file in imageFiles) {
      request.files.add(
        await http.MultipartFile.fromPath('files', file.path)
      );
    }
    
    var response = await request.send();
    
    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      var jsonData = jsonDecode(responseData);
      List<dynamic> uploadedImages = jsonData['uploaded_images'];
      return uploadedImages.map((img) => img['image_url'].toString()).toList();
    } else {
      var responseData = await response.stream.bytesToString();
      var errorMessage = 'Failed to upload images';
      
      try {
        var errorJson = jsonDecode(responseData);
        if (errorJson['detail'] != null) {
          errorMessage = errorJson['detail'];
        }
      } catch (e) {
        // If error parsing fails, use default message
      }
      
      throw Exception(errorMessage);
    }
  }

  // Generic get method for custom endpoints
  Future<Map<String, dynamic>> get(String endpoint, {Map<String, String>? queryParams}) async {
    final response = await _makeRequest('GET', endpoint, queryParams: queryParams);
    return jsonDecode(response.body);
  }

  // Generic put method for custom endpoints  
  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> body) async {
    final response = await _makeRequest('PUT', endpoint, body: body);
    return jsonDecode(response.body);
  }

  // Generic post method for custom endpoints
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    final response = await _makeRequest('POST', endpoint, body: body);
    return jsonDecode(response.body);
  }

  // Generic delete method for custom endpoints
  Future<Map<String, dynamic>> delete(String endpoint) async {
    final response = await _makeRequest('DELETE', endpoint);
    if (response.body.isEmpty) {
      return {'success': true};
    }
    return jsonDecode(response.body);
  }
}
