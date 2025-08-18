import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../blocs/payments/payments_bloc.dart';
import 'custom_button.dart';
import 'custom_text_field.dart';

class AddPaymentMethodBottomSheet extends StatefulWidget {
  const AddPaymentMethodBottomSheet({Key? key}) : super(key: key);

  @override
  State<AddPaymentMethodBottomSheet> createState() => _AddPaymentMethodBottomSheetState();
}

class _AddPaymentMethodBottomSheetState extends State<AddPaymentMethodBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  
  String _selectedPaymentType = 'credit_card';
  String _selectedProvider = 'visa';
  bool _isDefault = false;

  final List<PaymentType> _paymentTypes = [
    PaymentType('credit_card', 'Credit Card', Icons.credit_card),
    PaymentType('debit_card', 'Debit Card', Icons.credit_card),
    PaymentType('apple_pay', 'Apple Pay', Icons.apple),
    PaymentType('google_pay', 'Google Pay', Icons.g_mobiledata),
    PaymentType('paypal', 'PayPal', Icons.paypal),
    PaymentType('qris', 'QRIS', Icons.qr_code),
  ];

  final List<String> _cardProviders = ['visa', 'mastercard'];

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: BlocListener<PaymentsBloc, PaymentsState>(
        listener: (context, state) {
          if (state is PaymentMethodActionSuccess) {
            Navigator.of(context).pop();
          }
        },
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Payment type selection
                      Text(
                        'Payment Type',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _paymentTypes.map((type) {
                          final isSelected = _selectedPaymentType == type.id;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedPaymentType = type.id;
                                if (type.id == 'apple_pay') {
                                  _selectedProvider = 'apple_pay';
                                } else if (type.id == 'google_pay') {
                                  _selectedProvider = 'google_pay';
                                } else if (type.id == 'paypal') {
                                  _selectedProvider = 'paypal';
                                } else if (type.id == 'qris') {
                                  _selectedProvider = 'qris';
                                } else {
                                  _selectedProvider = 'visa';
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                    : Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected 
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    type.icon,
                                    size: 32,
                                    color: isSelected 
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.onSurface,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    type.name,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected 
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Dynamic form based on payment type
                      _buildPaymentForm(),
                      
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
              child: BlocBuilder<PaymentsBloc, PaymentsState>(
                builder: (context, state) {
                  return CustomButton(
                    text: 'Add Payment Method',
                    onPressed: _addPaymentMethod,
                    isLoading: state is PaymentMethodActionLoading,
                    icon: Icons.add,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    switch (_selectedPaymentType) {
      case 'credit_card':
      case 'debit_card':
        return _buildCardForm();
      case 'paypal':
        return _buildPayPalForm();
      case 'apple_pay':
      case 'google_pay':
        return _buildDigitalWalletForm();
      case 'qris':
        return _buildQRISForm();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card provider selection
        if (_selectedPaymentType == 'credit_card' || _selectedPaymentType == 'debit_card') ...[
          Text(
            'Card Provider',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: _cardProviders.map((provider) {
              final isSelected = _selectedProvider == provider;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedProvider = provider;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: provider == _cardProviders.last ? 0 : 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        provider.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
        
        // Card number
        Text(
          'Card Number',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: _cardNumberController,
          hintText: '1234 5678 9012 3456',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Please enter card number';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Expiry and CVV
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expiry Date',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _expiryController,
                    hintText: 'MM/YY',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CVV',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _cvvController,
                    hintText: '123',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Cardholder name
        Text(
          'Cardholder Name',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: _nameController,
          hintText: 'John Doe',
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Please enter cardholder name';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPayPalForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PayPal Email',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: _emailController,
          hintText: 'your.email@example.com',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Please enter your PayPal email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDigitalWalletForm() {
    final walletName = _selectedPaymentType == 'apple_pay' ? 'Apple Pay' : 'Google Pay';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            _selectedPaymentType == 'apple_pay' ? Icons.apple : Icons.g_mobiledata,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Connect $walletName',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You will be redirected to authenticate with $walletName',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQRISForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.qr_code,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Connect QRIS',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Indonesian QR Payment System\nLink your preferred QRIS provider',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _addPaymentMethod() {
    if (_formKey.currentState?.validate() ?? false) {
      Map<String, dynamic> accountInfo = {};
      
      switch (_selectedPaymentType) {
        case 'credit_card':
        case 'debit_card':
          accountInfo = {
            'card_number': _cardNumberController.text,
            'expiry': _expiryController.text,
            'cvv': _cvvController.text,
            'cardholder_name': _nameController.text,
            'last_four': _cardNumberController.text.replaceAll(' ', '').substring(
              _cardNumberController.text.replaceAll(' ', '').length - 4
            ),
          };
          break;
        case 'paypal':
          accountInfo = {
            'email': _emailController.text,
          };
          break;
        case 'apple_pay':
        case 'google_pay':
        case 'qris':
          accountInfo = {
            'connected': true,
          };
          break;
      }
      
      context.read<PaymentsBloc>().add(PaymentMethodAddEvent(paymentMethodData: {
        'type': _selectedPaymentType,
        'provider': _selectedProvider,
        'account_info': accountInfo,
        'is_default': _isDefault,
      }));
    }
  }
}

class PaymentType {
  final String id;
  final String name;
  final IconData icon;

  PaymentType(this.id, this.name, this.icon);
}