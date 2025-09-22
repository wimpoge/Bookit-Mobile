import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/payments/payments_bloc.dart';
import '../../blocs/bookings/bookings_bloc.dart';
import '../../models/payment.dart';
import '../../models/hotel.dart';
import '../../services/stripe_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/stripe_add_payment_method_bottom_sheet.dart';

class BookingPaymentScreen extends StatefulWidget {
  final Hotel hotel;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guests;

  const BookingPaymentScreen({
    Key? key,
    required this.hotel,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guests,
  }) : super(key: key);

  @override
  State<BookingPaymentScreen> createState() => _BookingPaymentScreenState();
}

class _BookingPaymentScreenState extends State<BookingPaymentScreen> {
  PaymentMethod? _selectedPaymentMethod;
  bool _isProcessingPayment = false;
  StripeService? _stripeService;

  @override
  void initState() {
    super.initState();
    _stripeService = StripeService(context.read<PaymentsBloc>().apiService);
    context.read<PaymentsBloc>().add(PaymentMethodsLoadEvent());
  }

  double get _totalPrice {
    final days = widget.checkOutDate.difference(widget.checkInDate).inDays;
    return widget.hotel.pricePerNight * days;
  }

  int get _numberOfNights {
    return widget.checkOutDate.difference(widget.checkInDate).inDays;
  }

  void _showAddPaymentMethodBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const StripeAddPaymentMethodBottomSheet(),
    ).then((_) {
      // Refresh payment methods after adding
      context.read<PaymentsBloc>().add(PaymentMethodsLoadEvent());
    });
  }

  Future<void> _processBookingWithPayment() async {
    try {
      setState(() => _isProcessingPayment = true);

      // First create a PENDING booking
      final bookingData = {
        'hotel_id': widget.hotel.id,
        'check_in_date': widget.checkInDate.toIso8601String(),
        'check_out_date': widget.checkOutDate.toIso8601String(),
        'guests': widget.guests,
      };

      context.read<BookingsBloc>().add(BookingCreateEvent(bookingData: bookingData));

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking creation failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Payment',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<BookingsBloc, BookingsState>(
            listener: (context, state) {
              if (state is BookingActionSuccess) {
                // Booking created successfully, now navigate to payment screen with 1-minute timeout
                context.go('/complete-payment/${state.booking.id}');
              } else if (state is BookingsError) {
                setState(() => _isProcessingPayment = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Booking failed: ${state.message}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          BlocListener<PaymentsBloc, PaymentsState>(
            listener: (context, state) {
              if (state is PaymentMethodActionSuccess) {
                // Reload payment methods after adding new one
                context.read<PaymentsBloc>().add(PaymentMethodsLoadEvent());
              }
            },
          ),
        ],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Booking Summary Card
              _buildBookingSummaryCard(),
              
              const SizedBox(height: 32),
              
              // Payment Methods Section
              Row(
                children: [
                  Text(
                    'Payment Method',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _showAddPaymentMethodBottomSheet,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      'Add New',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Payment Methods List
              BlocBuilder<PaymentsBloc, PaymentsState>(
                builder: (context, state) {
                  return _buildPaymentMethodsList(state);
                },
              ),
              
              const SizedBox(height: 32),
              
              // Price Breakdown
              _buildPriceBreakdown(),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
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
          text: 'Create Booking',
          onPressed: !_isProcessingPayment ? _processBookingWithPayment : null,
          isLoading: _isProcessingPayment,
          icon: Icons.bookmark_add,
        ),
      ),
    );
  }

  Widget _buildBookingSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hotel image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 80,
                  height: 80,
                  color: Theme.of(context).colorScheme.surface,
                  child: widget.hotel.images.isNotEmpty
                      ? Image.network(
                          widget.hotel.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(
                                Icons.hotel,
                                size: 40,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              ),
                        )
                      : Icon(
                          Icons.hotel,
                          size: 40,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Hotel details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.hotel.name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${widget.hotel.city}, ${widget.hotel.country}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.hotel.rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Divider(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
          
          const SizedBox(height: 16),
          
          // Booking details
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Check-in',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.checkInDate.day}/${widget.checkInDate.month}/${widget.checkInDate.year}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Check-out',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.checkOutDate.day}/${widget.checkOutDate.month}/${widget.checkOutDate.year}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guests',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.guests}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsList(PaymentsState state) {
    if (state is PaymentMethodsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    } else if (state is PaymentMethodsLoaded) {
      if (state.paymentMethods.isEmpty) {
        return _buildEmptyPaymentMethods();
      }
      
      return Column(
        children: state.paymentMethods.map((method) {
          return _buildPaymentMethodCard(method);
        }).toList(),
      );
    } else if (state is PaymentsError) {
      return _buildErrorState(state.message);
    }
    
    return _buildEmptyPaymentMethods();
  }

  Widget _buildPaymentMethodCard(PaymentMethod method) {
    final isSelected = _selectedPaymentMethod?.id == method.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = method;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
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
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getPaymentMethodIcon(method.provider),
                  color: _getPaymentMethodColor(method.provider),
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.displayName,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      method.type,
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
  }

  Widget _buildEmptyPaymentMethods() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.payment,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No payment methods',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a payment method to complete your booking',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Add Payment Method',
            onPressed: _showAddPaymentMethodBottomSheet,
            icon: Icons.add,
            width: 200,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading payment methods',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Retry',
            onPressed: () {
              context.read<PaymentsBloc>().add(PaymentMethodsLoadEvent());
            },
            width: 120,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown() {
    final subtotal = widget.hotel.pricePerNight * _numberOfNights;
    final taxes = subtotal * 0.12; // 12% tax
    final serviceFee = 15.0; // Fixed service fee
    final total = subtotal + taxes + serviceFee;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price Breakdown',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildPriceRow(
            '\$${widget.hotel.pricePerNight.toStringAsFixed(2)} x $_numberOfNights nights',
            '\$${subtotal.toStringAsFixed(2)}',
          ),
          
          const SizedBox(height: 8),
          
          _buildPriceRow(
            'Service fee',
            '\$${serviceFee.toStringAsFixed(2)}',
          ),
          
          const SizedBox(height: 8),
          
          _buildPriceRow(
            'Taxes',
            '\$${taxes.toStringAsFixed(2)}',
          ),
          
          const SizedBox(height: 16),
          
          Divider(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
          
          const SizedBox(height: 16),
          
          _buildPriceRow(
            'Total',
            '\$${total.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          amount,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  IconData _getPaymentMethodIcon(String provider) {
    switch (provider.toLowerCase()) {
      case 'visa':
        return Icons.credit_card;
      case 'mastercard':
        return Icons.credit_card;
      case 'apple_pay':
        return Icons.apple;
      case 'google_pay':
        return Icons.g_mobiledata;
      default:
        return Icons.payment;
    }
  }

  Color _getPaymentMethodColor(String provider) {
    switch (provider.toLowerCase()) {
      case 'visa':
        return Colors.blue;
      case 'mastercard':
        return Colors.red;
      case 'apple_pay':
        return Colors.black;
      case 'google_pay':
        return Colors.blue;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }
}