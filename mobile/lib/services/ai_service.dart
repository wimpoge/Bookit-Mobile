import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AIService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  final Dio _dio = Dio();

  AIService() {
    _dio.options.baseUrl = baseUrl;
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        options.headers['Content-Type'] = 'application/json';
        handler.next(options);
      },
      onError: (error, handler) {
        print('AI Service Error: ${error.message}');
        handler.next(error);
      },
    ));
  }

  Future<Map<String, dynamic>> sendMessage(String message) async {
    try {
      final response = await _dio.post(
        '/ai/chat',
        data: {'message': message},
      );

      if (response.statusCode == 200) {
        return {
          'success': response.data['success'] ?? true,
          'message': response.data['message'] ?? '',
          'data': response.data['data'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to send message: ${response.statusCode}',
          'data': null,
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['detail'] ?? 'Unknown error occurred';
        return {
          'success': false,
          'message': errorMessage,
          'data': null,
        };
      } else {
        return {
          'success': false,
          'message': 'Network error occurred. Please check your connection.',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: ${e.toString()}',
        'data': null,
      };
    }
  }
}