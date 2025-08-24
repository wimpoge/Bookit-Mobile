import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  static GlobalKey<NavigatorState>? _navigatorKey;
  
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  static BuildContext? get context => _navigatorKey?.currentContext;

  static void redirectToLogin() {
    final currentContext = context;
    if (currentContext != null && currentContext.mounted) {
      try {
        currentContext.go('/auth');
      } catch (e) {
        // Fallback to Navigator if GoRouter fails
        Navigator.of(currentContext).pushNamedAndRemoveUntil(
          '/auth', 
          (route) => false
        );
      }
    }
  }

  static void showSnackBar(String message, {Color? backgroundColor}) {
    final currentContext = context;
    if (currentContext != null && currentContext.mounted) {
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
        ),
      );
    }
  }
}