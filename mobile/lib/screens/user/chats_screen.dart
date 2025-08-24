import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/bookings/bookings_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../models/booking.dart';
import 'package:intl/intl.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({Key? key}) : super(key: key);

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  @override
  void initState() {
    super.initState();
    _loadBookingsData();
  }

  void _loadBookingsData() {
    final authState = context.read<AuthBloc>().state;
    print('ChatsScreen: Auth state is: ${authState.runtimeType}');
    
    if (authState is AuthAuthenticated) {
      print('ChatsScreen: User is authenticated, loading bookings');
      context.read<BookingsBloc>().add(BookingsLoadEvent());
    } else {
      print('ChatsScreen: User not authenticated');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthUnauthenticated) {
              print('ChatsScreen: User logged out, redirecting');
              context.go('/auth');
            } else if (state is AuthAuthenticated) {
              print('ChatsScreen: User authenticated via listener, reloading bookings');
              _loadBookingsData();
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'My Chats',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black87,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<BookingsBloc, BookingsState>(
      builder: (context, state) {
        if (state is BookingsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is BookingsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading chats',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
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
          );
        }

        if (state is BookingsLoaded) {
          // Show ALL bookings that can have chats (remove debugging filters)
          final chatBookings = state.bookings.where((booking) => 
            booking.status == BookingStatus.confirmed || 
            booking.status == BookingStatus.checkedIn ||
            booking.status == BookingStatus.checkedOut ||
            booking.status == BookingStatus.pending  // Allow pending bookings to have chats too
          ).toList();
          
          if (kDebugMode && chatBookings.isEmpty) {
            print('ChatsScreen: No chat-eligible bookings found from ${state.bookings.length} total bookings');
          }

          if (chatBookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.chat_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Chats Available',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chat with hotel owners will appear here\nonce you have confirmed bookings.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Explore Hotels'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<BookingsBloc>().add(BookingsLoadEvent());
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: chatBookings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final booking = chatBookings[index];
                return _buildChatTile(booking);
              },
            ),
          );
        }

        // Default state (initial)
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildChatTile(Booking booking) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.blue[100],
          child: Icon(
            Icons.hotel,
            color: Colors.blue[700],
            size: 24,
          ),
        ),
        title: Text(
          booking.hotel.ownerName ?? booking.hotel.name,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${booking.hotel.city}, ${booking.hotel.country}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status).withOpacity(0.1),
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
                const SizedBox(width: 8),
                Text(
                  '${DateFormat('MMM dd').format(booking.checkInDate)} - ${DateFormat('MMM dd').format(booking.checkOutDate)}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              color: Colors.blue[600],
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              'Chat',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.blue[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        onTap: () {
          // Pass both hotel ID and booking status to chat screen
          context.go('/chat/${booking.hotel.id}?bookingStatus=${booking.status.value}');
        },
      ),
    );
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