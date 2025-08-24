import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigationUtils {
  /// Safe navigation back that works with both GoRouter and Navigator
  static void goBack(BuildContext context) {
    try {
      // Try GoRouter first
      if (GoRouter.of(context).canPop()) {
        context.pop();
      } else {
        // Fallback to Navigator
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Final fallback
      try {
        Navigator.of(context).pop();
      } catch (e2) {
        debugPrint('Navigation error: Unable to go back');
      }
    }
  }

  /// Safe navigation that preserves state
  static void goBackSafely(BuildContext context) {
    try {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else if (GoRouter.of(context).canPop()) {
        context.pop();
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
    }
  }

  /// Custom back button widget that handles all navigation cases
  static Widget backButton(BuildContext context, {Color? color, VoidCallback? onPressed}) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: color),
      onPressed: onPressed ?? () => goBack(context),
    );
  }
}