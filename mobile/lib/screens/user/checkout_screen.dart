import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../blocs/bookings/bookings_bloc.dart';
import '../../blocs/reviews/reviews_bloc.dart';
import '../../models/booking.dart';
import '../../models/review.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class CheckoutScreen extends StatefulWidget {
  final String bookingId;

  const CheckoutScreen({
    Key? key,
    required this.bookingId,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _commentController = TextEditingController();
  final _pageController = PageController();
  
  int _rating = 5;
  int _currentPage = 0;
  bool _isCheckingOut = false;
  bool _hasCheckedOut = false;
  Booking? _booking;

  // Additional rating categories for detailed review
  int _cleanlinessRating = 5;
  int _serviceRating = 5;
  int _locationRating = 5;
  int _valueRating = 5;
  int _facilitiesRating = 5;

  @override
  void initState() {
    super.initState();
    context.read<BookingsBloc>().add(BookingDetailLoadEvent(bookingId: widget.bookingId));
  }

  @override
  void dispose() {
    _commentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _performCheckout() async {
    if (_booking == null) return;
    
    setState(() {
      _isCheckingOut = true;
    });

    try {
      context.read<BookingsBloc>().add(BookingSelfCheckOutEvent(bookingId: widget.bookingId));
    } catch (e) {
      setState(() {
        _isCheckingOut = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to check out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _submitReview() {
    if (_booking == null) return;

    final reviewData = {
      'booking_id': widget.bookingId,
      'rating': _rating,
      'comment': _commentController.text.trim(),
      'cleanliness_rating': _cleanlinessRating,
      'service_rating': _serviceRating,
      'location_rating': _locationRating,
      'value_rating': _valueRating,
      'facilities_rating': _facilitiesRating,
    };

    context.read<ReviewsBloc>().add(ReviewCreateEvent(reviewData: reviewData));
  }

  void _skipReview() {
    context.go('/bookings');
  }

  void _nextPage() {
    if (_currentPage < 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentPage == 0 ? 'Check Out' : 'Rate Your Stay',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentPage > 0) {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            } else {
              // Always navigate back to bookings screen
              context.go('/bookings');
            }
          },
        ),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<BookingsBloc, BookingsState>(
            listener: (context, state) {
              if (state is BookingCheckOutSuccess) {
                setState(() {
                  _isCheckingOut = false;
                  _hasCheckedOut = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Successfully checked out!'),
                    backgroundColor: Colors.green,
                  ),
                );
                _nextPage();
              } else if (state is BookingsError) {
                setState(() {
                  _isCheckingOut = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              } else if (state is BookingDetailLoaded) {
                setState(() {
                  _booking = state.booking;
                });
              }
            },
          ),
          BlocListener<ReviewsBloc, ReviewsState>(
            listener: (context, state) {
              if (state is ReviewCreateSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Review submitted successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
                context.go('/bookings');
              } else if (state is ReviewsError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
        child: BlocBuilder<BookingsBloc, BookingsState>(
          builder: (context, state) {
            if (state is BookingDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is BookingDetailLoaded || _booking != null) {
              final booking = state is BookingDetailLoaded ? state.booking : _booking!;
              
              return PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                physics: const NeverScrollableScrollPhysics(), // Disable swipe
                children: [
                  _buildCheckoutPage(booking),
                  _buildReviewPage(booking),
                ],
              );
            } else if (state is BookingsError) {
              return _buildErrorState(state.message);
            }
            
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildCheckoutPage(Booking booking) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hotel header
          _buildHotelHeader(booking),
          
          const SizedBox(height: 24),
          
          // Checkout confirmation
          Container(
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
                Row(
                  children: [
                    Icon(
                      Icons.logout,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Ready to Check Out?',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'We hope you enjoyed your stay at ${booking.hotel.name}. Please confirm your checkout below.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Stay summary
                _buildStaySummary(booking),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Checkout instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'After checkout, you\'ll have the option to rate your stay and help other travelers.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Checkout button
          BlocBuilder<BookingsBloc, BookingsState>(
            builder: (context, state) {
              return CustomButton(
                text: 'Check Out',
                onPressed: _hasCheckedOut ? null : _performCheckout,
                isLoading: _isCheckingOut || state is BookingActionLoading,
                icon: Icons.logout,
                backgroundColor: _hasCheckedOut ? Colors.green : null,
              );
            },
          ),
          
          if (_hasCheckedOut) ...[
            const SizedBox(height: 16),
            CustomButton(
              text: 'Continue to Review',
              onPressed: _nextPage,
              isOutlined: true,
              icon: Icons.star_outline,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewPage(Booking booking) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hotel header
          _buildHotelHeader(booking),
          
          const SizedBox(height: 24),
          
          Text(
            'How was your stay?',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Your feedback helps other travelers make informed decisions.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Overall rating
          _buildRatingSection('Overall Rating', _rating, (rating) {
            setState(() {
              _rating = rating;
            });
          }),
          
          const SizedBox(height: 24),
          
          // Detailed ratings
          Text(
            'Rate specific aspects',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildDetailedRatings(),
          
          const SizedBox(height: 24),
          
          // Comment section
          Text(
            'Write a review (optional)',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          
          const SizedBox(height: 12),
          
          CustomTextField(
            controller: _commentController,
            hintText: 'Share your experience with other travelers...',
            maxLines: 4,
          ),
          
          const SizedBox(height: 32),
          
          // Submit buttons
          BlocBuilder<ReviewsBloc, ReviewsState>(
            builder: (context, state) {
              return Column(
                children: [
                  CustomButton(
                    text: 'Submit Review',
                    onPressed: _submitReview,
                    isLoading: state is ReviewActionLoading,
                    icon: Icons.send,
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: 'Skip Review',
                    onPressed: _skipReview,
                    isOutlined: true,
                    textColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHotelHeader(Booking booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Hotel image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[300],
            ),
            child: booking.hotel.hasImages
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: booking.hotel.mainImage,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.hotel, color: Colors.grey),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.hotel, color: Colors.grey),
                      ),
                    ),
                  )
                : Icon(Icons.hotel, size: 32, color: Colors.grey[600]),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.hotel.name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        booking.hotel.fullAddress,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      booking.hotel.rating.toStringAsFixed(1),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaySummary(Booking booking) {
    return Column(
      children: [
        _buildSummaryRow(
          'Check-in',
          DateFormat('MMM dd, yyyy').format(booking.checkInDate),
          Icons.login,
        ),
        const SizedBox(height: 12),
        _buildSummaryRow(
          'Check-out',
          DateFormat('MMM dd, yyyy').format(booking.checkOutDate),
          Icons.logout,
        ),
        const SizedBox(height: 12),
        _buildSummaryRow(
          'Duration',
          '${booking.numberOfNights} night${booking.numberOfNights > 1 ? 's' : ''}',
          Icons.calendar_today,
        ),
        const SizedBox(height: 12),
        _buildSummaryRow(
          'Guests',
          '${booking.guests} guest${booking.guests > 1 ? 's' : ''}',
          Icons.people,
        ),
        const Divider(height: 24),
        _buildSummaryRow(
          'Total Paid',
          '\$${booking.totalPrice.toStringAsFixed(0)}',
          Icons.payment,
          isTotal: true,
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon, {bool isTotal = false}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isTotal 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 14 : 12,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(isTotal ? 1.0 : 0.6),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 16 : 12,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSection(String title, int rating, Function(int) onRatingChanged) {
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => onRatingChanged(index + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 36,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            _getRatingText(rating),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedRatings() {
    final ratings = [
      {'title': 'Cleanliness', 'value': _cleanlinessRating, 'setter': (int val) => setState(() => _cleanlinessRating = val)},
      {'title': 'Service', 'value': _serviceRating, 'setter': (int val) => setState(() => _serviceRating = val)},
      {'title': 'Location', 'value': _locationRating, 'setter': (int val) => setState(() => _locationRating = val)},
      {'title': 'Value for Money', 'value': _valueRating, 'setter': (int val) => setState(() => _valueRating = val)},
      {'title': 'Facilities', 'value': _facilitiesRating, 'setter': (int val) => setState(() => _facilitiesRating = val)},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: ratings.map((rating) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    rating['title'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () => (rating['setter'] as Function)(index + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Icon(
                            index < (rating['value'] as int) ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading booking',
              style: GoogleFonts.poppins(
                fontSize: 18,
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
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<BookingsBloc>().add(BookingDetailLoadEvent(bookingId: widget.bookingId));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Unknown';
    }
  }
}