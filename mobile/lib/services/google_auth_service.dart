import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  Future<GoogleSignInAccount?> signIn() async {
    try {
      print('GoogleAuthService: Starting Google Sign-In...');
      
      // Check if user is already signed in
      final bool isSignedIn = await _googleSignIn.isSignedIn();
      print('GoogleAuthService: Is already signed in: $isSignedIn');
      
      if (isSignedIn) {
        final currentUser = _googleSignIn.currentUser;
        print('GoogleAuthService: Current user: ${currentUser?.email}');
      }
      
      print('GoogleAuthService: Calling _googleSignIn.signIn()...');
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      
      if (account != null) {
        print('GoogleAuthService: Sign-in successful!');
        print('GoogleAuthService: User email: ${account.email}');
        print('GoogleAuthService: User name: ${account.displayName}');
        print('GoogleAuthService: User ID: ${account.id}');
      } else {
        print('GoogleAuthService: Sign-in was cancelled or failed');
      }
      
      return account;
    } catch (error) {
      print('GoogleAuthService: Sign-in error occurred: $error');
      print('GoogleAuthService: Error type: ${error.runtimeType}');
      print('GoogleAuthService: Error string: ${error.toString()}');
      
      // Handle MissingPluginException which occurs when Google Play Services
      // are not available or plugin is not properly configured
      if (error.toString().contains('MissingPluginException')) {
        print('GoogleAuthService: MissingPluginException - Google Sign-In plugin not available');
      } else if (error.toString().contains('PlatformException')) {
        print('GoogleAuthService: PlatformException - Check Google Services configuration');
      }
      
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (error) {
      if (kDebugMode) {
        print('Google Sign-Out error: $error');
      }
    }
  }

  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (error) {
      if (kDebugMode) {
        print('Google Silent Sign-In error: $error');
      }
      return null;
    }
  }

  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  Stream<GoogleSignInAccount?> get onCurrentUserChanged =>
      _googleSignIn.onCurrentUserChanged;
}

class GoogleUserData {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final String? idToken;
  final String? accessToken;

  GoogleUserData({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.idToken,
    this.accessToken,
  });

  static Future<GoogleUserData?> fromGoogleSignInAccount(
      GoogleSignInAccount account) async {
    try {
      final auth = await account.authentication;
      return GoogleUserData(
        id: account.id,
        email: account.email,
        name: account.displayName ?? '',
        photoUrl: account.photoUrl,
        idToken: auth.idToken,
        accessToken: auth.accessToken,
      );
    } catch (error) {
      if (kDebugMode) {
        print('Error getting Google user data: $error');
      }
      return null;
    }
  }
}