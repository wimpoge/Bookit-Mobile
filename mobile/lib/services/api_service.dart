import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/hotel.dart';
import '../models/booking.dart';
import '../models/payment.dart';
import '../models/review.dart';
import '../models/chat_message.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000/api';
  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<http.Response> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: queryParams,
    );

    http.Response response;
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

    if (response.statusCode >= 400) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Request failed');
    }

    return response;
  }

  // Auth endpoints
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _makeRequest('POST', '/auth/login', body: {
      'email': email,
      'password': password,
    });
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final response = await _makeRequest('POST', '/auth/register', body: userData);
    return jsonDecode(response.body);
  }

  // User endpoints
  Future<User> getCurrentUser() async {
    final response = await _makeRequest('GET', '/users/me');
    return User.fromJson(jsonDecode(response.body));
  }

  Future<User> updateUser(Map<String, dynamic> userData) async {
    final response = await _makeRequest('PUT', '/users/me', body: userData);
    return User.fromJson(jsonDecode(response.body));
  }

  // Hotel endpoints
  Future<List<Hotel>> getHotels({
    int skip = 0,
    int limit = 100,
    String? city,
    double? minPrice,
    double? maxPrice,
    String? amenities,
  }) async {
    final queryParams = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
      if (city != null) 'city': city,
      if (minPrice != null) 'min_price': minPrice.toString(),
      if (maxPrice != null) 'max_price': maxPrice.toString(),
      if (amenities != null) 'amenities': amenities,
    };

    final response = await _makeRequest('GET', '/hotels', queryParams: queryParams);
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
    final response = await _makeRequest('POST', '/hotels', body: hotelData);
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

  // Booking endpoints
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
    final response = await _makeRequest('POST', '/bookings', body: bookingData);
    return Booking.fromJson(jsonDecode(response.body));
  }

  Future<Booking> updateBooking(int id, Map<String, dynamic> bookingData) async {
    final response = await _makeRequest('PUT', '/bookings/$id', body: bookingData);
    return Booking.fromJson(jsonDecode(response.body));
  }

  Future<void> cancelBooking(int id) async {
    await _makeRequest('DELETE', '/bookings/$id');
  }

  Future<List<Booking>> getHotelBookings() async {
    final response = await _makeRequest('GET', '/bookings/owner/hotel-bookings');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Booking.fromJson(json)).toList();
  }

  Future<void> checkInBooking(int id) async {
    await _makeRequest('PUT', '/bookings/$id/check-in');
  }

  Future<void> checkOutBooking(int id) async {
    await _makeRequest('PUT', '/bookings/$id/check-out');
  }

  // Payment endpoints
  Future<List<PaymentMethod>> getPaymentMethods() async {
    final response = await _makeRequest('GET', '/payments/methods');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => PaymentMethod.fromJson(json)).toList();
  }

  Future<PaymentMethod> addPaymentMethod(Map<String, dynamic> paymentData) async {
    final response = await _makeRequest('POST', '/payments/methods', body: paymentData);
    return PaymentMethod.fromJson(jsonDecode(response.body));
  }

  Future<PaymentMethod> updatePaymentMethod(int id, Map<String, dynamic> paymentData) async {
    final response = await _makeRequest('PUT', '/payments/methods/$id', body: paymentData);
    return PaymentMethod.fromJson(jsonDecode(response.body));
  }

  Future<void> deletePaymentMethod(int id) async {
    await _makeRequest('DELETE', '/payments/methods/$id');
  }

  Future<Payment> processPayment(Map<String, dynamic> paymentData) async {
    final response = await _makeRequest('POST', '/payments/process', body: paymentData);
    return Payment.fromJson(jsonDecode(response.body));
  }

  Future<List<Payment>> getUserPayments() async {
    final response = await _makeRequest('GET', '/payments');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Payment.fromJson(json)).toList();
  }

  // Review endpoints
  Future<List<Review>> getHotelReviews(int hotelId) async {
    final response = await _makeRequest('GET', '/reviews/hotel/$hotelId');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Review.fromJson(json)).toList();
  }

  Future<Review> createReview(Map<String, dynamic> reviewData) async {
    final response = await _makeRequest('POST', '/reviews', body: reviewData);
    return Review.fromJson(jsonDecode(response.body));
  }

  Future<Review> updateReview(int id, Map<String, dynamic> reviewData) async {
    final response = await _makeRequest('PUT', '/reviews/$id', body: reviewData);
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

  // Chat endpoints
  Future<List<ChatMessage>> getChatMessages(int hotelId) async {
    final response = await _makeRequest('GET', '/chat/hotel/$hotelId');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => ChatMessage.fromJson(json)).toList();
  }

  Future<ChatMessage> sendMessage(int hotelId, String message) async {
    final response = await _makeRequest('POST', '/chat/hotel/$hotelId', body: {
      'hotel_id': hotelId,
      'message': message,
    });
    return ChatMessage.fromJson(jsonDecode(response.body));
  }

  Future<ChatMessage> ownerReply(int hotelId, String message) async {
    final response = await _makeRequest('POST', '/chat/hotel/$hotelId/owner-reply', body: {
      'hotel_id': hotelId,
      'message': message,
    });
    return ChatMessage.fromJson(jsonDecode(response.body));
  }

  Future<void> deleteMessage(int messageId) async {
    await _makeRequest('DELETE', '/chat/message/$messageId');
  }
}