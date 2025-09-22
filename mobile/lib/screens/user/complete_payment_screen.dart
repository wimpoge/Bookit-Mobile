import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../blocs/payments/payments_bloc.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';

class CompletePaymentScreen extends StatefulWidget {
  final String bookingId;

  const CompletePaymentScreen({
    Key? key,
    required this.bookingId,
  }) : super(key: key);

  @override
  State<CompletePaymentScreen> createState() => _CompletePaymentScreenState();
}

class _CompletePaymentScreenState extends State<CompletePaymentScreen> {
  bool _isCreatingPaymentLink = false;
  String? _paymentLinkId;
  String? _paymentUrl;
  int _timeoutMinutes = 10;
  Timer? _countdownTimer;
  int _remainingSeconds = 600; // 10 minutes
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = context.read<PaymentsBloc>().apiService;
    _createPaymentLink();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _createPaymentLink() async {
    try {
      setState(() => _isCreatingPaymentLink = true);

      print('🔄 Creating payment link for booking: ${widget.bookingId}');

      // Create payment link for this booking
      final response = await _apiService.createBookingPaymentLink(
        bookingId: widget.bookingId,
      );

      print('💳 Payment link response: $response');

      if (mounted) {
        setState(() {
          _paymentLinkId = response['payment_link_id'];
          _paymentUrl = response['payment_url'];
          _timeoutMinutes = response['timeout_minutes'] ?? 10;
          _remainingSeconds = _timeoutMinutes * 60;
          _isCreatingPaymentLink = false;
        });
      }

      print('🔗 Payment URL: $_paymentUrl');

      // Start countdown timer
      _startCountdownTimer();

    } catch (e) {
      if (mounted) {
        setState(() => _isCreatingPaymentLink = false);
        print('❌ Payment link creation error: $e');
        _showError('Failed to create payment link: $e');
      }
    }
  }

  void _startCountdownTimer() {
    print('⏰ Starting countdown timer for $_remainingSeconds seconds');

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });

        if (_remainingSeconds <= 0) {
          timer.cancel();
          print('⏰ Timer expired, showing timeout dialog');
          _showTimeoutDialog();
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Payment Timeout',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Payment time has expired. Your booking has been cancelled.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.pop(); // Close dialog
              context.go('/'); // Navigate back to home
            },
            child: Text(
              'OK',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    if (_paymentUrl == null) return;

    // Show in-app Stripe checkout
    await _showInAppCheckout();
  }

  Future<void> _showInAppCheckout() async {
    if (_paymentUrl == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StripeCheckoutWebView(
        paymentUrl: _paymentUrl!,
        bookingId: widget.bookingId,
        onPaymentSuccess: () {
          Navigator.of(context).pop(); // Close webview
          _showSuccessDialog();
        },
        onPaymentCancel: () {
          Navigator.of(context).pop(); // Close webview
        },
        onPaymentError: (error) {
          Navigator.of(context).pop(); // Close webview
          _showError('Payment failed: $error');
        },
      ),
    );
  }

  void _showCheckoutLaunchedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.open_in_browser,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Payment Page Opened',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Stripe payment page has opened in your browser.',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next steps:',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Complete payment in your browser\n'
                    '• You will receive email confirmation\n'
                    '• Return to the app to view your QR code',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.pop(); // Close dialog
              context.go('/bookings'); // Go to bookings to see updated status
            },
            child: Text(
              'Check Bookings',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.pop(); // Close dialog - stay on payment screen
            },
            child: Text(
              'Stay Here',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 32,
            ),
            const SizedBox(width: 12),
            Text(
              'Payment Successful!',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your booking has been confirmed. You will receive email confirmation and can view your QR code.',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 16),
            Text(
              'Booking ID: ${widget.bookingId}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.pop(); // Close dialog
              context.go('/bookings/${widget.bookingId}');
            },
            child: Text(
              'View Booking',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Complete Payment',
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
      body: _isCreatingPaymentLink
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Preparing payment...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeout Warning Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _remainingSeconds <= 300 ? Colors.red[50] : Colors.orange[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _remainingSeconds <= 300 ? Colors.red : Colors.orange,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer,
                          color: _remainingSeconds <= 300 ? Colors.red : Colors.orange,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment Timeout',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _remainingSeconds <= 300 ? Colors.red : Colors.orange,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Complete payment within ${_formatTime(_remainingSeconds)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: _remainingSeconds <= 300 ? Colors.red[700] : Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatTime(_remainingSeconds),
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _remainingSeconds <= 300 ? Colors.red : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Payment Instructions Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.credit_card,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Stripe Secure Checkout',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Complete your booking payment using Stripe\'s secure payment page.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.security,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'SSL encrypted • Email receipts • Invoices included',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Features
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.verified_user,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'What you\'ll get:',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...[
                          '✓ Instant email receipt from Stripe',
                          '✓ Professional invoice for your records',
                          '✓ QR code for easy hotel check-in',
                          '✓ 24/7 booking support',
                        ].map((feature) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                feature,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  height: 1.5,
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
      bottomNavigationBar: _isCreatingPaymentLink
          ? null
          : Container(
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
                text: 'Pay with Stripe',
                onPressed: _paymentUrl != null && _remainingSeconds > 0 ? _processPayment : null,
                isLoading: false,
                icon: Icons.credit_card,
              ),
            ),
    );
  }
}

class StripeCheckoutWebView extends StatefulWidget {
  final String paymentUrl;
  final String bookingId;
  final VoidCallback onPaymentSuccess;
  final VoidCallback onPaymentCancel;
  final Function(String) onPaymentError;

  const StripeCheckoutWebView({
    Key? key,
    required this.paymentUrl,
    required this.bookingId,
    required this.onPaymentSuccess,
    required this.onPaymentCancel,
    required this.onPaymentError,
  }) : super(key: key);

  @override
  State<StripeCheckoutWebView> createState() => _StripeCheckoutWebViewState();
}

class _StripeCheckoutWebViewState extends State<StripeCheckoutWebView> {
  late WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('🌐 Page started loading: $url');
          },
          onPageFinished: (String url) {
            print('✅ Page finished loading: $url');
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            print('🔄 Navigation request: ${request.url}');

            // Handle success redirect
            if (request.url.contains('payment-success')) {
              print('✅ Payment successful!');
              widget.onPaymentSuccess();
              return NavigationDecision.prevent;
            }

            // Handle cancel redirect
            if (request.url.contains('payment-cancel') || request.url.contains('cancel')) {
              print('❌ Payment cancelled');
              widget.onPaymentCancel();
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            print('❌ WebView error: ${error.description}');
            widget.onPaymentError(error.description);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.security,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Secure Stripe Checkout',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onPaymentCancel,
                ),
              ],
            ),
          ),

          // WebView
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  Container(
                    color: Colors.white,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading secure checkout...'),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}