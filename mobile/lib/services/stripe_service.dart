import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_service.dart';

class StripeService {
  static String get _publishableKey => dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
  
  final ApiService _apiService;

  StripeService(this._apiService);

  Future<void> initialize() async {
    try {
      Stripe.publishableKey = _publishableKey;
      
      // Configure Stripe
      await Stripe.instance.applySettings();
      
      if (kDebugMode) {
        print('Stripe initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Stripe: $e');
      }
      throw Exception('Failed to initialize Stripe: $e');
    }
  }

  /// Create a setup intent for saving payment method
  Future<String> createSetupIntent() async {
    try {
      final response = await _apiService.createSetupIntent();
      return response['client_secret'];
    } catch (e) {
      throw Exception('Failed to create setup intent: $e');
    }
  }

  /// Initialize payment sheet for adding payment method
  Future<void> initializePaymentSheet({required String clientSecret}) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          setupIntentClientSecret: clientSecret,
          merchantDisplayName: 'BookIt Hotels',
          style: ThemeMode.system,
          allowsDelayedPaymentMethods: true,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFF6366F1),
            ),
          ),
        ),
      );
    } catch (e) {
      throw Exception('Failed to initialize payment sheet: $e');
    }
  }

  /// Present payment sheet for payment method setup
  Future<String?> presentPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
      
      // If successful, the payment method is attached to the customer
      // Return success - the payment method ID will be handled by the backend
      return 'success';
    } catch (e) {
      if (e is StripeException) {
        throw Exception('Payment sheet error: ${e.error.localizedMessage}');
      }
      throw Exception('Failed to present payment sheet: $e');
    }
  }

  /// Create payment intent for booking
  Future<Map<String, dynamic>> createPaymentIntent({
    required String bookingId,
    required String paymentMethodId,
    bool confirm = true,
  }) async {
    try {
      return await _apiService.createPaymentIntent(
        bookingId: bookingId,
        paymentMethodId: paymentMethodId,
        confirm: confirm,
      );
    } catch (e) {
      throw Exception('Failed to create payment intent: $e');
    }
  }

  /// Initialize payment sheet for booking payment
  Future<void> initializeBookingPaymentSheet({
    required String clientSecret,
    required String bookingId,
  }) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'BookIt Hotels',
          style: ThemeMode.system,
          allowsDelayedPaymentMethods: false,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFF6366F1),
            ),
          ),
        ),
      );
    } catch (e) {
      throw Exception('Failed to initialize booking payment sheet: $e');
    }
  }

  /// Present payment sheet for booking payment
  Future<String> presentBookingPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
      return 'success';
    } catch (e) {
      if (e is StripeException) {
        if (e.error.code == FailureCode.Canceled) {
          throw Exception('Payment was cancelled');
        }
        throw Exception('Payment failed: ${e.error.localizedMessage}');
      }
      throw Exception('Payment failed: $e');
    }
  }

  /// Check if Apple Pay is supported
  Future<bool> isApplePaySupported() async {
    try {
      // Simplified check - Apple Pay is available on iOS devices
      return defaultTargetPlatform == TargetPlatform.iOS;
    } catch (e) {
      return false;
    }
  }

  /// Check if Google Pay is supported
  Future<bool> isGooglePaySupported() async {
    try {
      // Simplified check - Google Pay is available on Android devices
      return defaultTargetPlatform == TargetPlatform.android;
    } catch (e) {
      return false;
    }
  }

  /// Confirm payment intent
  Future<Map<String, dynamic>> confirmPayment({
    required String paymentIntentId,
  }) async {
    try {
      return await _apiService.confirmPayment(paymentIntentId);
    } catch (e) {
      throw Exception('Failed to confirm payment: $e');
    }
  }

  /// Save payment method to backend
  Future<void> savePaymentMethod({
    required String paymentMethodId,
    bool isDefault = false,
  }) async {
    try {
      await _apiService.addStripePaymentMethod(
        paymentMethodId: paymentMethodId,
        isDefault: isDefault,
      );
    } catch (e) {
      throw Exception('Failed to save payment method: $e');
    }
  }
}