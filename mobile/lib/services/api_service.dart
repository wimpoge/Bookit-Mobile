import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';

// Conditional imports for platform-specific functionality
import 'dart:io' as io show Platform;
// For web compatibility, we'll use dynamic typing for file operations
import '../models/user.dart';
import '../models/hotel.dart';
import '../models/booking.dart';
import '../models/payment.dart';
import '../models/review.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';
import '../models/user_statistics.dart';

class ApiService {
  static ApiService? _instance;
  
  // Singleton pattern
  static ApiService get instance {
    _instance ??= ApiService._internal();
    return _instance!;
  }
  
  // Method to set the singleton instance
  static void setInstance(ApiService apiService) {
    _instance = apiService;
  }
  
  // Private constructor
  ApiService._internal();
  
  // Public constructor for dependency injection (used in main.dart)
  ApiService();

  // Use different URLs based on platform and debug mode
  static String get baseUrl {
    String url;
    String platformInfo = 'web';
    
    if (kDebugMode) {
      // In debug mode, use appropriate URLs for different platforms
      try {
        if (kIsWeb) {
          url = 'http://localhost:8000/api';
          platformInfo = 'web';
        } else if (io.Platform.isAndroid) {
          // Use Android emulator special IP to access host machine
          url = 'http://10.0.2.2:8000/api';
          platformInfo = 'android';
        } else if (io.Platform.isIOS) {
          // iOS simulator can use localhost directly
          url = 'http://localhost:8000/api';
          platformInfo = 'ios';
        } else {
          // For other platforms (Windows, macOS, Linux)
          url = 'http://localhost:8000/api';
          platformInfo = 'desktop';
        }
      } catch (e) {
        // Fallback for web or unsupported platforms
        url = 'http://localhost:8000/api';
        platformInfo = 'unknown';
      }
    } else {
      // In release mode, use your production API URL
      url = 'https://your-production-api.com/api';
    }
    
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

    print('🌐 Making $method request to: $uri');
    if (body != null) {
      print('📤 Request body: ${jsonEncode(body)}');
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
      
      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');
    } catch (e) {
      print('❌ Request failed: $e');
      if (e.toString().contains('SocketException')) {
        throw Exception('Cannot connect to server. Please check if the backend is running on the correct address.');
      }
      rethrow;
    }


    if (response.statusCode >= 400) {
      
      // Handle token expiration (401 Unauthorized)
      if (response.statusCode == 401) {
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

  Future<UserStatistics> getUserStatistics() async {
    final response = await _makeRequest('GET', '/users/me/statistics');
    return UserStatistics.fromJson(jsonDecode(response.body));
  }

  Future<void> forgotPassword(String email) async {
    await _makeRequest('POST', '/auth/forgot-password', body: {
      'email': email,
    });
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
      if (city != null && city.isNotEmpty) 'city': city,
      if (minPrice != null) 'min_price': minPrice.toString(),
      if (maxPrice != null) 'max_price': maxPrice.toString(),
      if (amenities != null && amenities.isNotEmpty) 'amenities': amenities,
    };

    final response = await _makeRequest('GET', '/hotels/', queryParams: queryParams);
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Hotel.fromJson(json)).toList();
  }

  Future<List<Hotel>> getNearbyHotels({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int skip = 0,
    int limit = 100,
  }) async {
    final queryParams = <String, String>{
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'radius_km': radiusKm.toString(),
      'skip': skip.toString(),
      'limit': limit.toString(),
    };

    final response = await _makeRequest('GET', '/hotels/nearby', queryParams: queryParams);
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Hotel.fromJson(json)).toList();
  }

  Future<List<Hotel>> getHotelDeals({
    double? maxPrice,
    int skip = 0,
    int limit = 100,
  }) async {
    final queryParams = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
      if (maxPrice != null) 'max_price': maxPrice.toString(),
    };

    final response = await _makeRequest('GET', '/hotels/deals', queryParams: queryParams);
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

  Future<Hotel> getHotel(String id) async {
    final response = await _makeRequest('GET', '/hotels/$id');
    return Hotel.fromJson(jsonDecode(response.body));
  }

  Future<Hotel> createHotel(Map<String, dynamic> hotelData) async {
    final response = await _makeRequest('POST', '/hotels/', body: hotelData);
    return Hotel.fromJson(jsonDecode(response.body));
  }

  Future<Hotel> updateHotel(String id, Map<String, dynamic> hotelData) async {
    final response = await _makeRequest('PUT', '/hotels/$id', body: hotelData);
    return Hotel.fromJson(jsonDecode(response.body));
  }

  Future<void> deleteHotel(String id) async {
    await _makeRequest('DELETE', '/hotels/$id');
  }

  Future<Map<String, dynamic>> updateHotelDiscount(String hotelId, double discountPercentage) async {
    final response = await _makeRequest(
      'PATCH', 
      '/hotels/owner/$hotelId/discount',
      queryParams: {'discount_percentage': discountPercentage.toString()},
    );
    return jsonDecode(response.body);
  }

  Future<List<Hotel>> getOwnerHotels({
    int skip = 0,
    int limit = 100,
    String? city,
    String? status,
    String? sortBy,
    bool sortDesc = false,
    String? search,
    double? minPrice,
    double? maxPrice,
    double? minRating,
  }) async {
    final queryParams = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
      if (city != null && city.isNotEmpty) 'city': city,
      if (status != null && status.isNotEmpty) 'status': status,
      if (sortBy != null && sortBy.isNotEmpty) 'sort_by': sortBy,
      'sort_desc': sortDesc.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (minPrice != null) 'min_price': minPrice.toString(),
      if (maxPrice != null) 'max_price': maxPrice.toString(),
      if (minRating != null) 'min_rating': minRating.toString(),
    };

    final response = await _makeRequest('GET', '/hotels/owner/my-hotels', queryParams: queryParams);
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Hotel.fromJson(json)).toList();
  }

  Future<List<Booking>> getUserBookings() async {
    final response = await _makeRequest('GET', '/bookings');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Booking.fromJson(json)).toList();
  }

  Future<Booking> getBooking(String id) async {
    final response = await _makeRequest('GET', '/bookings/$id');
    return Booking.fromJson(jsonDecode(response.body));
  }

  Future<Booking> createBooking(Map<String, dynamic> bookingData) async {
    final response = await _makeRequest('POST', '/bookings/', body: bookingData);
    return Booking.fromJson(jsonDecode(response.body));
  }

  Future<Booking> updateBooking(
      String id, Map<String, dynamic> bookingData) async {
    final response =
        await _makeRequest('PUT', '/bookings/$id', body: bookingData);
    return Booking.fromJson(jsonDecode(response.body));
  }

  Future<void> cancelBooking(String id) async {
    await _makeRequest('DELETE', '/bookings/$id');
  }

  Future<List<Booking>> getHotelBookings() async {
    final response =
        await _makeRequest('GET', '/bookings/owner/hotel-bookings');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Booking.fromJson(json)).toList();
  }

  Future<void> confirmBooking(String id) async {
    await _makeRequest('PUT', '/bookings/$id/confirm');
  }

  Future<void> rejectBooking(String id) async {
    await _makeRequest('PUT', '/bookings/$id/reject');
  }

  Future<void> checkInBooking(String id) async {
    await _makeRequest('PUT', '/bookings/$id/check-in');
  }

  Future<void> checkOutBooking(String id) async {
    await _makeRequest('PUT', '/bookings/$id/check-out');
  }

  Future<void> selfCheckInBooking(String id) async {
    await _makeRequest('PUT', '/bookings/$id/self-checkin');
  }

  Future<void> selfCheckOutBooking(String id) async {
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
      String id, Map<String, dynamic> paymentData) async {
    final response =
        await _makeRequest('PUT', '/payments/methods/$id', body: paymentData);
    return PaymentMethod.fromJson(jsonDecode(response.body));
  }

  Future<void> deletePaymentMethod(String id) async {
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

  // Stripe-specific payment methods
  Future<Map<String, dynamic>> getStripeConfig() async {
    final response = await _makeRequest('GET', '/payments/config');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> createSetupIntent() async {
    final response = await _makeRequest('POST', '/payments/setup-intent');
    return jsonDecode(response.body);
  }

  Future<PaymentMethod> addStripePaymentMethod({
    required String paymentMethodId,
    bool isDefault = false,
  }) async {
    final response = await _makeRequest('POST', '/payments/methods', body: {
      'payment_method_id': paymentMethodId,
      'is_default': isDefault,
    });
    return PaymentMethod.fromJson(jsonDecode(response.body));
  }

  Future<Map<String, dynamic>> createPaymentIntent({
    required String bookingId,
    required String paymentMethodId,
    bool confirm = true,
  }) async {
    final response = await _makeRequest('POST', '/payments/create-payment-intent', body: {
      'booking_id': bookingId,
      'payment_method_id': paymentMethodId,
      'confirm': confirm,
    });
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> confirmPayment(String paymentIntentId) async {
    final response = await _makeRequest('POST', '/payments/confirm/$paymentIntentId');
    return jsonDecode(response.body);
  }

  // New booking payment methods with Stripe Payment Links
  Future<Map<String, dynamic>> createBookingPaymentLink({
    required String bookingId,
  }) async {
    final response = await _makeRequest('POST', '/payments/create-booking-payment-link', body: {
      'booking_id': bookingId,
    });
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> confirmPaymentLinkSuccess({
    required String bookingId,
    required String sessionId,
  }) async {
    final response = await _makeRequest('POST', '/payments/confirm-payment-link-success/$bookingId', body: {
      'session_id': sessionId,
    });
    return jsonDecode(response.body);
  }

  // Legacy method for backward compatibility
  Future<Map<String, dynamic>> createBookingPaymentIntent({
    required String bookingId,
  }) async {
    return createBookingPaymentLink(bookingId: bookingId);
  }

  Future<Map<String, dynamic>> confirmBookingPayment(String paymentIntentId) async {
    final response = await _makeRequest('POST', '/payments/confirm-booking-payment/$paymentIntentId');
    return jsonDecode(response.body);
  }

  Future<Booking> bookWithPayment({
    required Map<String, dynamic> bookingData,
    required String paymentMethodId,
  }) async {
    final Map<String, dynamic> requestBody = {
      ...bookingData,
    };
    
    final response = await _makeRequest(
      'POST', 
      '/bookings/book-with-payment?payment_method_id=$paymentMethodId', 
      body: requestBody
    );
    return Booking.fromJson(jsonDecode(response.body));
  }

  Future<List<Review>> getHotelReviews(String hotelId) async {
    final response = await _makeRequest('GET', '/reviews/hotel/$hotelId');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Review.fromJson(json)).toList();
  }

  Future<Review> createReview(Map<String, dynamic> reviewData) async {
    final response = await _makeRequest('POST', '/reviews/', body: reviewData);
    return Review.fromJson(jsonDecode(response.body));
  }

  Future<Review> updateReview(String id, Map<String, dynamic> reviewData) async {
    final response =
        await _makeRequest('PUT', '/reviews/$id', body: reviewData);
    return Review.fromJson(jsonDecode(response.body));
  }

  Future<Review> replyToReview(String id, String reply) async {
    final response = await _makeRequest('PUT', '/reviews/$id/reply', body: {
      'owner_reply': reply,
    });
    return Review.fromJson(jsonDecode(response.body));
  }

  Future<void> deleteReview(String id) async {
    await _makeRequest('DELETE', '/reviews/$id');
  }

  Future<List<Review>> getUserReviews() async {
    final response = await _makeRequest('GET', '/reviews/user/my-reviews');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Review.fromJson(json)).toList();
  }

  Future<List<ChatMessage>> getChatMessages(String hotelId) async {
    final response = await _makeRequest('GET', '/chat/hotel/$hotelId');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => ChatMessage.fromJson(json)).toList();
  }

  Future<ChatMessage> sendMessage(String hotelId, String message) async {
    
    final response = await _makeRequest('POST', '/chat/hotel/$hotelId', body: {
      'message': message,
    });
    
    
    return ChatMessage.fromJson(jsonDecode(response.body));
  }

  Future<ChatMessage> ownerReply(String hotelId, String message) async {
    final response =
        await _makeRequest('POST', '/chat/hotel/$hotelId/owner-reply', body: {
      'message': message,
    });
    return ChatMessage.fromJson(jsonDecode(response.body));
  }

  Future<void> deleteMessage(String messageId) async {
    await _makeRequest('DELETE', '/chat/message/$messageId');
  }

  Future<List<ChatConversation>> getOwnerConversations() async {
    final response = await _makeRequest('GET', '/chat/owner/conversations');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => ChatConversation.fromJson(json)).toList();
  }

  Future<List<ChatMessage>> getChatMessagesForOwner({
    required String hotelId,
    required String userId,
  }) async {
    final response =
        await _makeRequest('GET', '/chat/owner/chats/$hotelId/$userId');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => ChatMessage.fromJson(json)).toList();
  }

  Future<ChatMessage> sendOwnerMessage({
    required String hotelId,
    required String userId,
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
    required String hotelId,
    String? userId,
  }) async {
    try {
      await _makeRequest('POST', '/chat/mark-read', body: {
        'hotel_id': hotelId,
        if (userId != null) 'user_id': userId,
      });
    } catch (e) {
    }
  }

  Future<String> uploadHotelImage(String fileName, Uint8List imageBytes) async {
    var request = http.MultipartRequest(
      'POST', 
      Uri.parse('$baseUrl/hotels/upload-image')
    );
    
    // Add authorization header
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    
    // Add the file using bytes (works on both web and mobile)
    request.files.add(
      http.MultipartFile.fromBytes(
        'file', 
        imageBytes,
        filename: fileName,
      )
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

  Future<List<String>> uploadHotelImages(List<Map<String, dynamic>> imageData, {String? hotelName}) async {
    // imageData format: [{'name': 'filename.jpg', 'bytes': Uint8List}, ...]
    
    // Client-side validation
    if (imageData.length > 10) {
      throw Exception('Maximum 10 images allowed. Please select fewer images.');
    }
    
    if (imageData.isEmpty) {
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
    
    // Add hotel name if provided
    if (hotelName != null && hotelName.isNotEmpty) {
      request.fields['hotel_name'] = hotelName;
    }
    
    // Add all files using bytes
    for (var imageFile in imageData) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'files',
          imageFile['bytes'] as Uint8List,
          filename: imageFile['name'] as String,
        )
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

  // Favorites methods
  Future<List<Hotel>> getFavoriteHotels({
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
        await _makeRequest('GET', '/favorites/hotels', queryParams: queryParams);
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Hotel.fromJson(json)).toList();
  }

  Future<void> addHotelToFavorites(String hotelId) async {
    await _makeRequest('POST', '/favorites/add/$hotelId');
  }

  Future<void> removeHotelFromFavorites(String hotelId) async {
    await _makeRequest('DELETE', '/favorites/remove/$hotelId');
  }

  Future<bool> isHotelFavorite(String hotelId) async {
    final response = await _makeRequest('GET', '/favorites/check/$hotelId');
    final data = jsonDecode(response.body);
    return data['is_favorite'] ?? false;
  }
}
