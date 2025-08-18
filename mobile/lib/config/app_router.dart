import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth/auth_bloc.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/user/main_screen.dart';
import '../screens/user/home_screen.dart';
import '../screens/user/bookings_screen.dart';
import '../screens/user/payment_screen.dart';
import '../screens/user/chat_screen.dart';
import '../screens/user/profile_screen.dart';
import '../screens/user/hotel_detail_screen.dart';
import '../screens/user/booking_detail_screen.dart';
import '../screens/user/review_screen.dart';
import '../screens/owner/owner_main_screen.dart';
import '../screens/owner/owner_hotels_screen.dart';
import '../screens/owner/add_hotel_screen.dart';
import '../screens/owner/owner_bookings_screen.dart';
import '../screens/owner/owner_profile_screen.dart';
import '../screens/owner/edit_hotel_screen.dart';
import '../screens/owner/hotel_reviews_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>();

  static GoRouter get router => _router;

  static final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final authState = context.read<AuthBloc>().state;
      final isAuthenticated = authState is AuthAuthenticated;
      final isOwner = isAuthenticated && authState.user.role == 'owner';

      final loginRoutes = ['/login', '/register'];
      final userRoutes = [
        '/home',
        '/bookings',
        '/payment',
        '/chat',
        '/profile'
      ];
      final ownerRoutes = [
        '/owner',
        '/owner/hotels',
        '/owner/bookings',
        '/owner/profile'
      ];

      if (!isAuthenticated && !loginRoutes.contains(state.location)) {
        return '/login';
      }

      if (isAuthenticated) {
        if (isOwner &&
            userRoutes.any((route) => state.location.startsWith(route))) {
          return '/owner';
        }
        if (!isOwner &&
            ownerRoutes.any((route) => state.location.startsWith(route))) {
          return '/home';
        }
        if (loginRoutes.contains(state.location)) {
          return isOwner ? '/owner' : '/home';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
            routes: [
              GoRoute(
                path: 'hotel/:id',
                builder: (context, state) => HotelDetailScreen(
                  hotelId: int.parse(state.params['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/bookings',
            builder: (context, state) => const BookingsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => BookingDetailScreen(
                  bookingId: int.parse(state.params['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/payment',
            builder: (context, state) => const PaymentScreen(),
          ),
          GoRoute(
            path: '/chat/:hotelId',
            builder: (context, state) => ChatScreen(
              hotelId: int.parse(state.params['hotelId']!),
            ),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/review/:bookingId',
            builder: (context, state) => ReviewScreen(
              bookingId: int.parse(state.params['bookingId']!),
            ),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => OwnerMainScreen(child: child),
        routes: [
          GoRoute(
            path: '/owner',
            redirect: (context, state) => '/owner/hotels',
          ),
          GoRoute(
            path: '/owner/hotels',
            builder: (context, state) => const OwnerHotelsScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const AddHotelScreen(),
              ),
              GoRoute(
                path: 'edit/:id',
                builder: (context, state) => EditHotelScreen(
                  hotelId: int.parse(state.params['id']!),
                ),
              ),
              GoRoute(
                path: ':id/reviews',
                builder: (context, state) => HotelReviewsScreen(
                  hotelId: int.parse(state.params['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/owner/bookings',
            builder: (context, state) => const OwnerBookingsScreen(),
          ),
          GoRoute(
            path: '/owner/profile',
            builder: (context, state) => const OwnerProfileScreen(),
          ),
        ],
      ),
    ],
  );
}
