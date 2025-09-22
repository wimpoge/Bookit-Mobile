import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../blocs/payments/payments_bloc.dart';
import '../services/stripe_service.dart';
import 'custom_button.dart';

class StripeAddPaymentMethodBottomSheet extends StatefulWidget {
  const StripeAddPaymentMethodBottomSheet({Key? key}) : super(key: key);

  @override
  State<StripeAddPaymentMethodBottomSheet> createState() => _StripeAddPaymentMethodBottomSheetState();
}

class _StripeAddPaymentMethodBottomSheetState extends State<StripeAddPaymentMethodBottomSheet> {
  bool _isDefault = false;
  bool _isLoading = false;
  String _selectedPaymentType = 'card';
  StripeService? _stripeService;

  final List<PaymentMethodOption> _paymentMethods = [
    PaymentMethodOption('card', 'Credit/Debit Card', Icons.credit_card),
    // Temporarily disabled Apple Pay and Google Pay due to API compatibility
    // PaymentMethodOption('apple_pay', 'Apple Pay', Icons.apple),
    // PaymentMethodOption('google_pay', 'Google Pay', Icons.g_mobiledata),
  ];

  @override
  void initState() {
    super.initState();
    _stripeService = StripeService(context.read<PaymentsBloc>().apiService);
  }

  Future<void> _addCardPaymentMethod() async {
    try {
      setState(() => _isLoading = true);

      // Create setup intent
      final clientSecret = await _stripeService!.createSetupIntent();

      // Initialize payment sheet
      await _stripeService!.initializePaymentSheet(clientSecret: clientSecret);

      // Present payment sheet
      final result = await _stripeService!.presentPaymentSheet();

      if (result == 'success') {
        // Payment method setup successful
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment method added successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Refresh payment methods list
          context.read<PaymentsBloc>().add(PaymentMethodsLoadEvent());
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add payment method: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addApplePayMethod() async {
    try {
      setState(() => _isLoading = true);

      final isSupported = await _stripeService!.isApplePaySupported();
      if (!isSupported) {
        throw Exception('Apple Pay is not supported on this device');
      }

      // For demonstration, we'll simulate adding Apple Pay
      // In a real implementation, you'd integrate with Apple Pay setup
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Apple Pay setup completed'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Apple Pay setup failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addGooglePayMethod() async {
    try {
      setState(() => _isLoading = true);

      final isSupported = await _stripeService!.isGooglePaySupported();
      if (!isSupported) {
        throw Exception('Google Pay is not supported on this device');
      }

      // For demonstration, we'll simulate adding Google Pay
      // In a real implementation, you'd integrate with Google Pay setup
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Pay setup completed'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Pay setup failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addPaymentMethod() {
    switch (_selectedPaymentType) {
      case 'card':
        _addCardPaymentMethod();
        break;
      // Temporarily disabled
      // case 'apple_pay':
      //   _addApplePayMethod();
      //   break;
      // case 'google_pay':
      //   _addGooglePayMethod();
      //   break;
      default:
        _addCardPaymentMethod();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Add Payment Method',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose a payment method to add',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Payment method options
                  ..._paymentMethods.map((method) {
                    final isSelected = _selectedPaymentType == method.id;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedPaymentType = method.id;
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected 
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                                      : Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  method.icon,
                                  color: isSelected 
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface,
                                  size: 24,
                                ),
                              ),
                              
                              const SizedBox(width: 16),
                              
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      method.name,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getMethodDescription(method.id),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              if (isSelected)
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    size: 16,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  
                  const SizedBox(height: 24),
                  
                  // Set as default checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _isDefault,
                        onChanged: (value) {
                          setState(() {
                            _isDefault = value ?? false;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Set as default payment method',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          
          // Bottom button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: CustomButton(
              text: 'Add Payment Method',
              onPressed: _isLoading ? null : _addPaymentMethod,
              isLoading: _isLoading,
              icon: Icons.add,
            ),
          ),
        ],
      ),
    );
  }

  String _getMethodDescription(String methodId) {
    switch (methodId) {
      case 'card':
        return 'Securely add your credit or debit card';
      // Temporarily disabled
      // case 'apple_pay':
      //   return 'Pay with your Touch ID or Face ID';
      // case 'google_pay':
      //   return 'Pay with your Google account';
      default:
        return 'Securely add your payment method';
    }
  }
}

class PaymentMethodOption {
  final String id;
  final String name;
  final IconData icon;

  PaymentMethodOption(this.id, this.name, this.icon);
}