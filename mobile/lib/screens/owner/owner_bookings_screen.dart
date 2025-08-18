import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../blocs/bookings/bookings_bloc.dart';
import '../../models/booking.dart';
import '../../widgets/owner_booking_card.dart';

class OwnerBookingsScreen extends StatefulWidget {
  const OwnerBookingsScreen({Key? key}) : super(key: key);

  @override
  State<OwnerBookingsScreen> createState() => _OwnerBookingsScreenState();
}

class _OwnerBookingsScreenState extends State<OwnerBookingsScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    context.read<BookingsBloc>().add(OwnerBookingsLoadEvent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bookings Management',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Confirmed'),
            Tab(text: 'Check-ins'),
            Tab(text: 'Check-outs'),
            Tab(text: 'All'),
          ],
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
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
            // Reload bookings
            context.read<BookingsBloc>().add(OwnerBookingsLoadEvent());
          } else if (state is BookingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is BookingsLoading || state is BookingActionLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is BookingsError) {
            return _buildErrorState(state.message);
          } else if (state is BookingsLoaded) {
            return _buildBookingTabs(state.bookings);
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
              'Error loading bookings',
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
                context.read<BookingsBloc>().add(OwnerBookingsLoadEvent());
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingTabs(List<Booking> bookings) {
    final confirmedBookings = bookings.where((b) => 
        b.status == BookingStatus.confirmed).toList();
    final checkInBookings = bookings.where((b) => 
        b.status == BookingStatus.confirmed && 
        b.checkInDate.isBefore(DateTime.now().add(const Duration(days: 1)))).toList();
    final checkOutBookings = bookings.where((b) => 
        b.status == BookingStatus.checkedIn).toList();

    return Column(
      children: [
        // Stats header
        _buildStatsHeader(bookings),
        
        // Tabs content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildBookingsList(confirmedBookings, OwnerBookingType.confirmed),
              _buildBookingsList(checkInBookings, OwnerBookingType.checkIn),
              _buildBookingsList(checkOutBookings, OwnerBookingType.checkOut),
              _buildBookingsList(bookings, OwnerBookingType.all),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsHeader(List<Booking> bookings) {
    final today = DateTime.now();
    final todayBookings = bookings.where((b) => 
        b.checkInDate.day == today.day &&
        b.checkInDate.month == today.month &&
        b.checkInDate.year == today.year).length;
    
    final totalRevenue = bookings
        .where((b) => b.status != BookingStatus.cancelled)
        .fold<double>(0, (sum, booking) => sum + booking.totalPrice);

    return Container(
      margin: const EdgeInsets.all(20),
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
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Today\'s Overview',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '${bookings.length}',
                  'Total Bookings',
                  Icons.book_online,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  '$todayBookings',
                  'Today\'s Check-ins',
                  Icons.login,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  '\$${totalRevenue.toStringAsFixed(0)}',
                  'Total Revenue',
                  Icons.attach_money,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.onPrimary,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList(List<Booking> bookings, OwnerBookingType type) {
    if (bookings.isEmpty) {
      return _buildEmptyState(type);
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<BookingsBloc>().add(OwnerBookingsLoadEvent());
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        itemCount: bookings.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return OwnerBookingCard(
            booking: booking,
            type: type,
            onCheckIn: booking.canCheckIn 
                ? () => _performAction(booking, 'check-in')
                : null,
            onCheckOut: booking.canCheckOut 
                ? () => _performAction(booking, 'check-out')
                : null,
            onCancel: booking.canCancel 
                ? () => _showCancelDialog(booking)
                : null,
            onViewDetails: () => _showBookingDetails(booking),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(OwnerBookingType type) {
    String title;
    String subtitle;
    IconData icon;

    switch (type) {
      case OwnerBookingType.confirmed:
        title = 'No confirmed bookings';
        subtitle = 'New bookings will appear here';
        icon = Icons.book_online;
        break;
      case OwnerBookingType.checkIn:
        title = 'No check-ins today';
        subtitle = 'Guests checking in today will appear here';
        icon = Icons.login;
        break;
      case OwnerBookingType.checkOut:
        title = 'No check-outs';
        subtitle = 'Guests ready to check out will appear here';
        icon = Icons.logout;
        break;
      case OwnerBookingType.all:
        title = 'No bookings yet';
        subtitle = 'All bookings will appear here';
        icon = Icons.calendar_month;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _performAction(Booking booking, String action) {
    switch (action) {
      case 'check-in':
        context.read<BookingsBloc>().add(BookingCheckInEvent(bookingId: booking.id));
        break;
      case 'check-out':
        context.read<BookingsBloc>().add(BookingCheckOutEvent(bookingId: booking.id));
        break;
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
          'Are you sure you want to cancel the booking for ${booking.hotel.name}? This action cannot be undone.',
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

  void _showBookingDetails(Booking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                    'Booking Details',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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
                    // Guest info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Guest Information',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Booking ID: #${booking.id}',
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hotel: ${booking.hotel.name}',
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Guests: ${booking.guests}',
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Check-in: ${DateFormat('MMM dd, yyyy').format(booking.checkInDate)}',
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Check-out: ${DateFormat('MMM dd, yyyy').format(booking.checkOutDate)}',
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total: \$${booking.totalPrice.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum OwnerBookingType {
  confirmed,
  checkIn,
  checkOut,
  all,
}