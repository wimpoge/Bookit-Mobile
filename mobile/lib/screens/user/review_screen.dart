import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../blocs/bookings/bookings_bloc.dart';
import '../../blocs/reviews/reviews_bloc.dart';
import '../../models/booking.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ReviewScreen extends StatefulWidget {
  final int bookingId;

  const ReviewScreen({
    Key? key,
    required this.bookingId,
  }) : super(key: key);

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _commentController = TextEditingController();
  int _rating = 5;
  Booking? _booking;

  @override
  void initState() {
    super.initState();
    context.read<BookingsBloc>().add(BookingDetailLoadEvent(bookingId: widget.bookingId));
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Write Review',
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
      body: BlocConsumer<BookingsBloc, BookingsState>(
        listener: (context, state) {
          if (state is BookingDetailLoaded) {
            setState(() {
              _booking = state.booking;
            });
          }
        },
        builder: (context, bookingState) {
          if (bookingState is BookingDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (bookingState is BookingsError) {
            return _buildErrorState(bookingState.message);
          } else if (_booking != null) {
            return _buildReviewForm();
          }
          
          return const SizedBox.shrink();
        },
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

  Widget _buildReviewForm() {
    return BlocConsumer<ReviewsBloc, ReviewsState>(
      listener: (context, state) {
        if (state is ReviewActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        } else if (state is ReviewsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hotel info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: _booking!.hotel.hasImages
                          ? Image.network(
                              _booking!.hotel.mainImage,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.hotel, color: Colors.grey[600]);
                              },
                            )
                          : Icon(Icons.hotel, color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _booking!.hotel.name,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_booking!.hotel.city}, ${_booking!.hotel.country}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'COMPLETED',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Rating section
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
              'Rate your overall experience',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Star rating
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        size: 40,
                        color: Colors.amber,
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Rating description
            Center(
              child: Text(
                _getRatingDescription(_rating),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Comment section
            Text(
              'Tell us more about your experience',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Share details about your stay to help other travelers (optional)',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
              ),
            ),
            
            const SizedBox(height: 16),
            
            CustomTextField(
              controller: _commentController,
              hintText: 'Write your review here...',
              maxLines: 6,
              validator: null,
            ),
            
            const SizedBox(height: 32),
            
            // Quick comment suggestions
            Text(
              'Quick Comments',
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
              children: _getQuickComments().map((comment) {
                return GestureDetector(
                  onTap: () {
                    final currentText = _commentController.text.trim();
                    if (currentText.isEmpty) {
                      _commentController.text = comment;
                    } else {
                      _commentController.text = '$currentText $comment';
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      comment,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 48),
            
            // Submit button
            BlocBuilder<ReviewsBloc, ReviewsState>(
              builder: (context, state) {
                return CustomButton(
                  text: 'Submit Review',
                  onPressed: _submitReview,
                  isLoading: state is ReviewActionLoading,
                  icon: Icons.send,
                );
              },
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _getRatingDescription(int rating) {
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
        return 'Rate your stay';
    }
  }

  List<String> _getQuickComments() {
    switch (_rating) {
      case 5:
        return [
          'Amazing experience!',
          'Perfect location',
          'Excellent service',
          'Great value for money',
          'Highly recommend',
          'Beautiful rooms',
          'Outstanding staff'
        ];
      case 4:
        return [
          'Very good stay',
          'Nice facilities',
          'Good service',
          'Clean and comfortable',
          'Would stay again',
          'Great amenities'
        ];
      case 3:
        return [
          'Decent stay',
          'Average service',
          'Good location',
          'Fair value',
          'Room was okay',
          'Could be better'
        ];
      case 2:
        return [
          'Below expectations',
          'Room needs improvement',
          'Service was slow',
          'Not great value',
          'Some issues encountered'
        ];
      case 1:
        return [
          'Very disappointed',
          'Poor service',
          'Room was not clean',
          'Would not recommend',
          'Many problems'
        ];
      default:
        return [];
    }
  }

  void _submitReview() {
    if (_booking == null) return;
    
    final reviewData = {
      'booking_id': _booking!.id,
      'rating': _rating,
      'comment': _commentController.text.trim().isEmpty 
          ? null 
          : _commentController.text.trim(),
    };
    
    context.read<ReviewsBloc>().add(ReviewCreateEvent(reviewData: reviewData));
  }
}