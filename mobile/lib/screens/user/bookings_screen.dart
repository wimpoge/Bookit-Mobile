import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../blocs/bookings/bookings_bloc.dart';
import '../../models/booking.dart';
import '../../widgets/booking_card.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({Key? key}) : super(key: key);

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  static int _savedTabIndex = 0; // Static variable to remember tab index

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: _savedTabIndex);
    _tabController.addListener(_onTabChanged);
    context.read<BookingsBloc>().add(BookingsLoadEvent());
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _savedTabIndex = _tabController.index;
      print('BookingsScreen: Tab changed to index $_savedTabIndex');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Bookings',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Current'),
            Tab(text: 'Past'),
            Tab(text: 'Cancelled'),
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
            context.read<BookingsBloc>().add(BookingsLoadEvent());
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
            Image.asset(
              'assets/images/500.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
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
                context.read<BookingsBloc>().add(BookingsLoadEvent());
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingTabs(List<Booking> bookings) {
    final currentBookings = bookings.where((b) => b.isCurrent).toList();
    final pastBookings = bookings.where((b) => b.isPast).toList();
    final cancelledBookings = bookings.where((b) => b.status == BookingStatus.cancelled).toList();

    return TabBarView(
      controller: _tabController,
      children: [
        _buildBookingsList(currentBookings, BookingListType.current),
        _buildBookingsList(pastBookings, BookingListType.past),
        _buildBookingsList(cancelledBookings, BookingListType.cancelled),
      ],
    );
  }

  Widget _buildBookingsList(List<Booking> bookings, BookingListType type) {
    if (bookings.isEmpty) {
      return _buildEmptyState(type);
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<BookingsBloc>().add(BookingsLoadEvent());
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: bookings.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return BookingCard(
            booking: booking,
            type: type,
            onTap: () {
              // Navigate to booking detail and ensure current tab is preserved
              context.go('/bookings/${booking.id}');
            },
            onCancel: type == BookingListType.current && booking.canCancel
                ? () => _showCancelDialog(booking)
                : null,
            onReview: type == BookingListType.past && booking.canReview
                ? () => context.go('/review/${booking.id}')
                : null,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BookingListType type) {
    String title;
    String subtitle;

    switch (type) {
      case BookingListType.current:
        title = 'No current bookings';
        subtitle = 'Your active stays will appear here';
        break;
      case BookingListType.past:
        title = 'No past bookings';
        subtitle = 'Your completed stays will appear here';
        break;
      case BookingListType.cancelled:
        title = 'No cancelled bookings';
        subtitle = 'Cancelled bookings will appear here';
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/No Bookings Found.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (type == BookingListType.current) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Explore Hotels'),
              ),
            ],
          ],
        ),
      ),
    );
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

enum BookingListType {
  current,
  past,
  cancelled,
}