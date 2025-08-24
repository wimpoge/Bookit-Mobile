import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'navigation_service.dart';
import 'google_auth_service.dart';
import '../models/user.dart';

class AuthService {
  final ApiService _apiService;
  final SharedPreferences _prefs;

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  AuthService(this._apiService, this._prefs) {
    _apiService.setTokenExpiredCallback(_handleTokenExpired);
  }

  void _handleTokenExpired() {
    logout();
    NavigationService.redirectToLogin();
    NavigationService.showSnackBar(
      'Your session has expired. Please log in again.',
      backgroundColor: Colors.orange,
    );
  }

  Future<bool> get isAuthenticated async {
    final token = await getToken();
    return token != null;
  }

  Future<String?> getToken() async {
    return _prefs.getString(_tokenKey);
  }

  Future<User?> getCurrentUser() async {
    final userJson = _prefs.getString(_userKey);
    if (userJson != null) {
      try {
        return User.fromJson(userJson);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<LoginResult> login(String email, String password) async {
    try {
      final response = await _apiService.login(email, password);

      final token = response['access_token'];
      final user = User.fromJson(response['user']);

      await _prefs.setString(_tokenKey, token);
      await _prefs.setString(_userKey, user.toJson());

      _apiService.setToken(token);

      return LoginResult.success(user);
    } catch (e) {
      return LoginResult.failure(e.toString());
    }
  }

  Future<RegisterResult> register(Map<String, dynamic> userData) async {
    try {
      final response = await _apiService.register(userData);

      final token = response['access_token'];
      final user = User.fromJson(response['user']);

      await _prefs.setString(_tokenKey, token);
      await _prefs.setString(_userKey, user.toJson());

      _apiService.setToken(token);

      return RegisterResult.success(user);
    } catch (e) {
      return RegisterResult.failure(e.toString());
    }
  }

  Future<void> logout() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userKey);
    _apiService.setToken(null);
  }

  Future<void> initializeToken() async {
    final token = await getToken();
    print('AuthService: Initializing token. Token found: ${token != null}');
    if (token != null) {
      print('AuthService: Setting token in API service: ${token.substring(0, 20)}...');
      _apiService.setToken(token);
    } else {
      print('AuthService: No stored token found');
    }
  }

  Future<User?> updateProfile(Map<String, dynamic> userData) async {
    try {
      final user = await _apiService.updateUser(userData);
      await _prefs.setString(_userKey, user.toJson());
      return user;
    } catch (e) {
      return null;
    }
  }

  Future<LoginResult> googleLogin() async {
    try {
      print('AuthService: Starting Google login process...');
      
      final googleAccount = await GoogleAuthService().signIn();
      if (googleAccount == null) {
        print('AuthService: Google account is null - sign-in cancelled or failed');
        return LoginResult.failure("Google sign-in was cancelled or not available. Please use email/password login instead.");
      }

      print('AuthService: Google account obtained: ${googleAccount.email}');
      print('AuthService: Getting Google user data...');
      
      final googleUserData = await GoogleUserData.fromGoogleSignInAccount(googleAccount);
      if (googleUserData == null || googleUserData.idToken == null) {
        print('AuthService: Failed to get Google user data or ID token');
        print('AuthService: GoogleUserData: $googleUserData');
        print('AuthService: ID Token available: ${googleUserData?.idToken != null}');
        return LoginResult.failure("Failed to get Google user data");
      }

      print('AuthService: Google user data obtained successfully');
      print('AuthService: Email: ${googleUserData.email}');
      print('AuthService: Name: ${googleUserData.name}');
      print('AuthService: ID Token length: ${googleUserData.idToken?.length}');
      
      print('AuthService: Sending Google login request to backend...');
      final response = await _apiService.googleLogin(googleUserData.idToken!);
      print('AuthService: Backend response received');
      
      final token = response['access_token'];
      final user = User.fromJson(response['user']);

      print('AuthService: Storing token and user data...');
      await _prefs.setString(_tokenKey, token);
      await _prefs.setString(_userKey, user.toJson());

      _apiService.setToken(token);
      print('AuthService: Google login completed successfully');

      return LoginResult.success(user);
    } catch (e) {
      print('AuthService: Google login error: $e');
      print('AuthService: Error type: ${e.runtimeType}');
      
      String errorMessage = e.toString();
      if (errorMessage.contains('MissingPluginException')) {
        errorMessage = "Google Sign-In is not available on this device. Please use email/password login instead.";
      }
      return LoginResult.failure(errorMessage);
    }
  }
}

class LoginResult {
  final bool isSuccess;
  final User? user;
  final String? error;

  LoginResult._(this.isSuccess, this.user, this.error);

  factory LoginResult.success(User user) => LoginResult._(true, user, null);
  factory LoginResult.failure(String error) =>
      LoginResult._(false, null, error);
}

class RegisterResult {
  final bool isSuccess;
  final User? user;
  final String? error;

  RegisterResult._(this.isSuccess, this.user, this.error);

  factory RegisterResult.success(User user) =>
      RegisterResult._(true, user, null);
  factory RegisterResult.failure(String error) =>
      RegisterResult._(false, null, error);
}
