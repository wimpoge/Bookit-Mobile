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
  
  Function()? _onTokenExpiredCallback;

  AuthService(this._apiService, this._prefs) {
    _apiService.setTokenExpiredCallback(_handleTokenExpired);
  }

  void setTokenExpiredCallback(Function() callback) {
    _onTokenExpiredCallback = callback;
  }

  void _handleTokenExpired() {
    logout();
    _onTokenExpiredCallback?.call();
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
    if (token != null) {
      _apiService.setToken(token);
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
      final googleAccount = await GoogleAuthService().signIn();
      if (googleAccount == null) {
        return LoginResult.failure("Google sign-in was cancelled or not available. Please use email/password login instead.");
      }

      final googleUserData = await GoogleUserData.fromGoogleSignInAccount(googleAccount);
      if (googleUserData == null || googleUserData.idToken == null) {
        return LoginResult.failure("Failed to get Google user data");
      }

      final response = await _apiService.googleLogin(googleUserData.idToken!);
      
      final token = response['access_token'];
      final user = User.fromJson(response['user']);

      await _prefs.setString(_tokenKey, token);
      await _prefs.setString(_userKey, user.toJson());

      _apiService.setToken(token);

      return LoginResult.success(user);
    } catch (e) {
      
      String errorMessage = e.toString();
      if (errorMessage.contains('MissingPluginException')) {
        errorMessage = "Google Sign-In is not available on this device. Please use email/password login instead.";
      }
      return LoginResult.failure(errorMessage);
    }
  }

  Future<ForgotPasswordResult> forgotPassword(String email) async {
    try {
      await _apiService.forgotPassword(email);
      return ForgotPasswordResult.success();
    } catch (e) {
      return ForgotPasswordResult.failure(e.toString());
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

class ForgotPasswordResult {
  final bool isSuccess;
  final String? error;

  ForgotPasswordResult._(this.isSuccess, this.error);

  factory ForgotPasswordResult.success() => ForgotPasswordResult._(true, null);
  factory ForgotPasswordResult.failure(String error) =>
      ForgotPasswordResult._(false, error);
}
