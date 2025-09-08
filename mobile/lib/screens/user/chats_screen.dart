import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/bookings/bookings_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../models/booking.dart';
import 'package:intl/intl.dart';
import '../../widgets/simple_ai_chat.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({Key? key}) : super(key: key);

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> with TickerProviderStateMixin {
  final GlobalKey<SimpleAIChatState> _aiChatKey = GlobalKey<SimpleAIChatState>();
  bool _isAiChatVisible = false;
  AnimationController? _animationController;
  Animation<double>? _heightAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200), // Faster animation
      vsync: this,
    );
    _heightAnimation = Tween<double>(
      begin: 0.06, // Smaller minimized state
      end: 0.6,    // Reduced expanded state height
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.fastOutSlowIn, // Better curve for performance
    ));
    _loadBookingsData();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
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
          elevation: 0,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isAiChatVisible = true;
                  });
                  _animationController?.forward(); // Start expanded
                },
                icon: const Icon(Icons.smart_toy, size: 18),
                label: Text(
                  'Ask AI',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            _buildBody(),
            if (_isAiChatVisible) _buildAIChatOverlay(),
          ],
        ),
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
                Image.asset(
                  'assets/images/500.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
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
                  Image.asset(
                    'assets/images/No Chats Found.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chat with hotel owners will appear here\nonce you have confirmed bookings.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
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

  Widget _buildAIChatOverlay() {
    if (_heightAnimation == null) {
      return const SizedBox.shrink();
    }
    
    return AnimatedBuilder(
      animation: _heightAnimation!,
      builder: (context, child) {
        final screenHeight = MediaQuery.of(context).size.height;
        final height = screenHeight * _heightAnimation!.value;
        final isMinimized = _heightAnimation!.value < 0.3;
        
        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: height.clamp(0, screenHeight - MediaQuery.of(context).viewPadding.top - 20), // Ensure it doesn't overflow top
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              // Optimized drag tracking with less frequent updates
              if (_animationController != null && details.delta.dy.abs() > 1.0) {
                final dragDelta = -details.delta.dy / screenHeight;
                final newValue = (_animationController!.value + dragDelta * 2.0).clamp(0.0, 1.0); // 2x sensitivity for smoother feel
                _animationController!.value = newValue;
              }
            },
            onVerticalDragEnd: (details) {
              // Snap to nearest position with velocity consideration
              if (_animationController != null) {
                final velocity = details.velocity.pixelsPerSecond.dy;
                if (velocity > 300) {
                  // Fast swipe down = minimize
                  _animationController!.animateTo(0.0, duration: const Duration(milliseconds: 150));
                } else if (velocity < -300) {
                  // Fast swipe up = expand  
                  _animationController!.animateTo(1.0, duration: const Duration(milliseconds: 150));
                } else {
                  // Slow drag = snap to nearest
                  if (_animationController!.value < 0.5) {
                    _animationController!.animateTo(0.0, duration: const Duration(milliseconds: 150));
                  } else {
                    _animationController!.animateTo(1.0, duration: const Duration(milliseconds: 150));
                  }
                }
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag handle area with title when minimized
                  Container(
                    width: double.infinity,
                    height: isMinimized ? 50 : 30,
                    color: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: isMinimized 
                        ? Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.smart_toy,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'AI Assistant',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              Container(
                                width: 30,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          )
                        : Center(
                            child: Container(
                              width: 50,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                  ),
                  if (!isMinimized)
                    Expanded(
                      child: SimpleAIChat(
                        key: _aiChatKey,
                        onClose: () {
                          _aiChatKey.currentState?.clearChat();
                          setState(() {
                            _isAiChatVisible = false;
                          });
                          _animationController?.reset();
                        },
                      ),
                    ),
                  if (isMinimized)
                    const SizedBox.shrink(), // Just show the drag handle when minimized
                ],
              ),
            ),
          ),
        );
      },
    );
  }

}