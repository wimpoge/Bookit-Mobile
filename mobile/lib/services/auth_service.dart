import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../models/user.dart';

class AuthService {
  final ApiService _apiService;
  final SharedPreferences _prefs;
  
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  AuthService(this._apiService, this._prefs);

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
}

class LoginResult {
  final bool isSuccess;
  final User? user;
  final String? error;

  LoginResult._(this.isSuccess, this.user, this.error);

  factory LoginResult.success(User user) => LoginResult._(true, user, null);
  factory LoginResult.failure(String error) => LoginResult._(false, null, error);
}

class RegisterResult {
  final bool isSuccess;
  final User? user;
  final String? error;

  RegisterResult._(this.isSuccess, this.user, this.error);

  factory RegisterResult.success(User user) => RegisterResult._(true, user, null);
  factory RegisterResult.failure(String error) => RegisterResult._(false, null, error);
}