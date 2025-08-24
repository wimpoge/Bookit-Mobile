import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../blocs/bookings/bookings_bloc.dart';
import '../../models/booking.dart';
import '../../models/review.dart';
import '../../widgets/custom_button.dart';

class BookingDetailScreen extends StatefulWidget {
  final int bookingId;

  const BookingDetailScreen({
    Key? key,
    required this.bookingId,
  }) : super(key: key);

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<BookingsBloc>().add(BookingDetailLoadEvent(bookingId: widget.bookingId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Booking Details',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Always navigate back to bookings screen
            context.go('/bookings');
          },
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'contact_hotel':
                  // TODO: Contact hotel
                  break;
                case 'help':
                  // TODO: Get help
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'contact_hotel',
                child: Row(
                  children: [
                    const Icon(Icons.phone),
                    const SizedBox(width: 8),
                    Text('Contact Hotel', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'help',
                child: Row(
                  children: [
                    const Icon(Icons.help_outline),
                    const SizedBox(width: 8),
                    Text('Get Help', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: BlocConsumer<BookingsBloc, BookingsState>(
        listener: (context, state) {
          if (state is BookingCancelSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            context.pop();
          } else if (state is BookingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is BookingsLoaded) {
            // Refresh booking detail when main bookings are loaded (e.g., after review submission)
            context.read<BookingsBloc>().add(BookingDetailLoadEvent(bookingId: widget.bookingId));
          }
        },
        builder: (context, state) {
          if (state is BookingDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is BookingDetailLoaded) {
            return _buildBookingDetail(state.booking);
          } else if (state is BookingsError) {
            return _buildErrorState(state.message);
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

  Widget _buildBookingDetail(Booking booking) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Hotel Images
          Container(
            height: 200,
            child: booking.hotel.hasImages
                ? PageView.builder(
                    itemCount: booking.hotel.images.length,
                    itemBuilder: (context, index) {
                      return CachedNetworkImage(
                        imageUrl: booking.hotel.images[index],
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: Icon(Icons.hotel, size: 64, color: Colors.grey[600]),
                        ),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey[300],
                    child: Icon(Icons.hotel, size: 64, color: Colors.grey[600]),
                  ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Booking status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(booking.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(booking.status),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(booking.status),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Booking #${booking.id}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Hotel name and location
                Text(
                  booking.hotel.name,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        booking.hotel.fullAddress,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Booking details cards
                _buildDetailCard(
                  'Check-in',
                  DateFormat('EEEE, MMM dd, yyyy').format(booking.checkInDate),
                  DateFormat('HH:mm').format(booking.checkInDate),
                  Icons.login,
                ),
                
                const SizedBox(height: 16),
                
                _buildDetailCard(
                  'Check-out',
                  DateFormat('EEEE, MMM dd, yyyy').format(booking.checkOutDate),
                  DateFormat('HH:mm').format(booking.checkOutDate),
                  Icons.logout,
                ),
                
                const SizedBox(height: 16),
                
                _buildDetailCard(
                  'Guests',
                  '${booking.guests} guest${booking.guests > 1 ? 's' : ''}',
                  '${booking.numberOfNights} night${booking.numberOfNights > 1 ? 's' : ''}',
                  Icons.people_outline,
                ),
                
                const SizedBox(height: 24),
                
                // Price breakdown
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
                      Text(
                        'Price Details',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\$${booking.hotel.pricePerNight.toStringAsFixed(0)} x ${booking.numberOfNights} nights',
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                          Text(
                            '\$${booking.totalPrice.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${booking.totalPrice.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Hotel amenities
                if (booking.hotel.amenities.isNotEmpty) ...[
                  Text(
                    'Amenities',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: booking.hotel.amenities.map((amenity) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          amenity,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // User's Review (if exists)
                if (booking.review != null) ...[
                  _buildReviewSection(booking.review!),
                  const SizedBox(height: 24),
                ],
                
                // Action buttons
                _buildActionButtons(booking),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, String main, String sub, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  main,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  sub,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection(Review review) {
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
          Row(
            children: [
              Icon(
                Icons.rate_review,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Your Review',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Star rating
          Row(
            children: [
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  );
                }),
              ),
              const SizedBox(width: 8),
              Text(
                '${review.rating}/5',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.5,
              ),
            ),
          ],
          
          const SizedBox(height: 12),
          Text(
            'Reviewed on ${DateFormat('MMM dd, yyyy').format(review.createdAt)}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          
          // Owner reply if exists
          if (review.ownerReply != null && review.ownerReply!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.business,
                        color: Theme.of(context).colorScheme.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Hotel Response',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    review.ownerReply!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(Booking booking) {
    if (booking.canCancel) {
      return Column(
        children: [
          CustomButton(
            text: 'Chat with Hotel',
            onPressed: () => context.go('/chat/${booking.hotel.id}'),
            isOutlined: true,
            icon: Icons.chat_bubble_outline,
          ),
          const SizedBox(height: 12),
          BlocBuilder<BookingsBloc, BookingsState>(
            builder: (context, state) {
              return CustomButton(
                text: 'Cancel Booking',
                onPressed: () => _showCancelDialog(booking),
                isLoading: state is BookingActionLoading,
                backgroundColor: Colors.red,
                icon: Icons.cancel_outlined,
              );
            },
          ),
        ],
      );
    } else if (booking.canCheckOut) {
      return Column(
        children: [
          CustomButton(
            text: 'Check Out & Review',
            onPressed: () => context.go('/checkout/${booking.id}'),
            icon: Icons.logout,
            backgroundColor: Colors.green,
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: 'Chat with Hotel',
            onPressed: () => context.go('/chat/${booking.hotel.id}'),
            isOutlined: true,
            icon: Icons.chat_bubble_outline,
          ),
        ],
      );
    } else if (booking.canReview) {
      return Column(
        children: [
          CustomButton(
            text: 'Write Review',
            onPressed: () => context.go('/review/${booking.id}'),
            icon: Icons.star_outline,
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: 'Book Again',
            onPressed: () => context.go('/hotel/${booking.hotel.id}'),
            isOutlined: true,
            icon: Icons.refresh,
          ),
        ],
      );
    } else {
      return Column(
        children: [
          CustomButton(
            text: 'View Hotel',
            onPressed: () => context.go('/hotel/${booking.hotel.id}'),
            icon: Icons.hotel,
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: 'Chat with Hotel',
            onPressed: () => context.go('/chat/${booking.hotel.id}'),
            isOutlined: true,
            icon: Icons.chat_bubble_outline,
          ),
        ],
      );
    }
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.blue;
      case BookingStatus.checkedIn:
        return Colors.green;
      case BookingStatus.checkedOut:
        return Colors.grey;
      case BookingStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'PENDING CONFIRMATION';
      case BookingStatus.confirmed:
        return 'CONFIRMED';
      case BookingStatus.checkedIn:
        return 'CHECKED IN';
      case BookingStatus.checkedOut:
        return 'COMPLETED';
      case BookingStatus.cancelled:
        return 'CANCELLED';
    }
  }

  void _showCancelDialog(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cancel Booking',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to cancel your booking at ${booking.hotel.name}? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Keep Booking',
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<BookingsBloc>().add(BookingCancelEvent(bookingId: booking.id));
            },
            child: Text(
              'Cancel Booking',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}