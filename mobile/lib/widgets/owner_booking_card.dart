import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/booking.dart';
import '../screens/owner/owner_bookings_screen.dart';

class OwnerBookingCard extends StatelessWidget {
  final Booking booking;
  final OwnerBookingType type;
  final VoidCallback? onConfirm;
  final VoidCallback? onReject;
  final VoidCallback? onCheckIn;
  final VoidCallback? onCheckOut;
  final VoidCallback? onCancel;
  final VoidCallback onViewDetails;

  const OwnerBookingCard({
    Key? key,
    required this.booking,
    required this.type,
    this.onConfirm,
    this.onReject,
    this.onCheckIn,
    this.onCheckOut,
    this.onCancel,
    required this.onViewDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onViewDetails,
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: SizedBox(
                    width: 100,
                    height: 140,
                    child: booking.hotel.hasImages
                        ? CachedNetworkImage(
                            imageUrl: booking.hotel.mainImage,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                _PlaceholderImage(),
                          )
                        : _PlaceholderImage(),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(booking.status)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _getStatusText(booking.status),
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(booking.status),
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '#${booking.id}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          booking.hotel.name,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${booking.hotel.city}, ${booking.hotel.country}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${DateFormat('MMM dd').format(booking.checkInDate)} - ${DateFormat('MMM dd, yyyy').format(booking.checkOutDate)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${booking.guests} guest${booking.guests > 1 ? 's' : ''} • ${booking.numberOfNights} night${booking.numberOfNights > 1 ? 's' : ''}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total amount',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                        ),
                        Text(
                          '\$${booking.totalPrice.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildActionButtons(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (booking.status == BookingStatus.pending &&
        onConfirm != null &&
        onReject != null) {
      return Row(
        children: [
          OutlinedButton(
            onPressed: onReject,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              side: BorderSide(color: Colors.red.withOpacity(0.6)),
            ),
            child: Text(
              'Reject',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              backgroundColor: Colors.green,
            ),
            child: Text(
              'Confirm',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    } else if (onCheckIn != null) {
      return Row(
        children: [
          ElevatedButton(
            onPressed: onViewDetails,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
            ),
            child: Text(
              'View',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onCheckIn,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              backgroundColor: Colors.blue,
            ),
            child: Text(
              'Check In',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    } else if (onCheckOut != null) {
      return Row(
        children: [
          ElevatedButton(
            onPressed: onViewDetails,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
            ),
            child: Text(
              'View',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onCheckOut,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              backgroundColor: Colors.orange,
            ),
            child: Text(
              'Check Out',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    } else if (onCancel != null) {
      return Row(
        children: [
          OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              side: BorderSide(color: Colors.red.withOpacity(0.6)),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onViewDetails,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
            ),
            child: Text(
              'View',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    } else {
      return ElevatedButton(
        onPressed: onViewDetails,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: Size.zero,
        ),
        child: Text(
          'View Details',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
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
        return 'PENDING';
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
}

class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[300],
      child: Icon(
        Icons.hotel,
        size: 32,
        color: Colors.grey[600],
      ),
    );
  }
}
