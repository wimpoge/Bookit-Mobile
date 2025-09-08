import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/navigation_service.dart';

import '../blocs/auth/auth_bloc.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/user/main_screen.dart';
import '../screens/user/home_screen.dart';
import '../screens/user/bookings_screen.dart';
import '../screens/user/payment_screen.dart';
import '../screens/user/chat_screen.dart';
import '../screens/user/profile_screen.dart';
import '../screens/user/hotel_detail_screen.dart';
import '../screens/user/booking_detail_screen.dart';
import '../screens/user/review_screen.dart';
import '../screens/user/checkout_screen.dart';
import '../screens/user/reviews_screen.dart';
import '../screens/user/chats_screen.dart';
import '../screens/user/favorites_screen.dart';
import '../screens/owner/owner_main_screen.dart';
import '../screens/owner/owner_hotels_screen.dart';
import '../screens/owner/owner_chats_screen.dart';
import '../screens/owner/owner_chat_screen.dart';
import '../screens/owner/add_hotel_screen.dart';
import '../screens/owner/owner_bookings_screen.dart';
import '../screens/owner/owner_profile_screen.dart';
import '../screens/owner/edit_hotel_screen.dart';
import '../screens/owner/hotel_reviews_screen.dart';
import '../screens/settings/language_settings_screen.dart';
import '../screens/settings/help_support_screen.dart';
import '../screens/settings/privacy_security_screen.dart';
import '../screens/settings/about_screen.dart';
import '../screens/settings/notifications_screen.dart';
import '../screens/owner/analytics_reports_screen.dart';
import '../screens/owner/owner_help_support_screen.dart';
import '../screens/owner/owner_reviews_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>();

  static GoRouter get router {
    NavigationService.setNavigatorKey(_rootNavigatorKey);
    return _router;
  }

  static final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/', // Changed to splash screen
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/404.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            Text('Page not found: ${state.matchedLocation}'),
            const SizedBox(height: 8),
            Text('Full location: ${state.fullPath}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    ),
    redirect: (context, state) {
      // Skip redirect for splash screen
      if (state.matchedLocation == '/') {
        return null;
      }

      final authBloc = context.read<AuthBloc>();
      final authState = authBloc.state;
      final isAuthenticated = authState is AuthAuthenticated;
      final isOwner = isAuthenticated && authState.user.role == 'owner';

      final authRoutes = ['/auth', '/login', '/register', '/forgot-password'];
      final userRoutes = [
        '/home',
        '/bookings',
        '/chats',
        '/payment',
        '/chat',
        '/profile'
      ];
      final ownerRoutes = [
        '/owner',
        '/owner/hotels',
        '/owner/bookings',
        '/owner/chats',
        '/owner/profile'
      ];

      final location = state.matchedLocation;

      if (!isAuthenticated &&
          !authRoutes.contains(location) &&
          !location.startsWith('/auth') &&
          !location.startsWith('/forgot-password')) {
        return '/auth';
      }

      if (isAuthenticated) {
        if (isOwner && userRoutes.any((route) => location.startsWith(route))) {
          return '/owner/hotels';
        }
        if (!isOwner &&
            ownerRoutes.any((route) => location.startsWith(route))) {
          return '/home';
        }
        if (authRoutes.contains(location)) {
          return isOwner ? '/owner/hotels' : '/home';
        }
      }

      return null;
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const AuthScreen(initiallyShowLogin: true),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) =>
            const AuthScreen(initiallyShowLogin: false),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/hotel/:id',
            builder: (context, state) => HotelDetailScreen(
              hotelId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/bookings',
            builder: (context, state) => const BookingsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => BookingDetailScreen(
                  bookingId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/chats',
            builder: (context, state) => const ChatsScreen(),
          ),
          GoRoute(
            path: '/payment',
            builder: (context, state) => const PaymentScreen(),
          ),
          GoRoute(
            path: '/chat/:hotelId',
            builder: (context, state) => ChatScreen(
              hotelId: state.pathParameters['hotelId']!,
              bookingStatus: state.uri.queryParameters['bookingStatus'],
            ),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'favorites',
                builder: (context, state) => const FavoritesScreen(),
              ),
              GoRoute(
                path: 'language',
                builder: (context, state) => const LanguageSettingsScreen(),
              ),
              GoRoute(
                path: 'help',
                builder: (context, state) => const HelpSupportScreen(),
              ),
              GoRoute(
                path: 'privacy',
                builder: (context, state) => const PrivacySecurityScreen(),
              ),
              GoRoute(
                path: 'about',
                builder: (context, state) => const AboutScreen(),
              ),
              GoRoute(
                path: 'notifications',
                builder: (context, state) => const NotificationsScreen(),
              ),
              GoRoute(
                path: 'reviews',
                builder: (context, state) => const ReviewsScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/review/:bookingId',
            builder: (context, state) => ReviewScreen(
              bookingId: state.pathParameters['bookingId']!,
            ),
          ),
          GoRoute(
            path: '/checkout/:bookingId',
            builder: (context, state) => CheckoutScreen(
              bookingId: state.pathParameters['bookingId']!,
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
                  hotelId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: ':id/reviews',
                builder: (context, state) => HotelReviewsScreen(
                  hotelId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/owner/bookings',
            builder: (context, state) => const OwnerBookingsScreen(),
          ),
          GoRoute(
            path: '/owner/chats',
            builder: (context, state) => const OwnerChatsScreen(),
          ),
          GoRoute(
            path: '/owner/chats/:hotelId/:userId',
            builder: (context, state) => OwnerChatScreen(
              hotelId: state.pathParameters['hotelId']!,
              userId: state.pathParameters['userId']!,
            ),
          ),
          GoRoute(
            path: '/owner/profile',
            builder: (context, state) => const OwnerProfileScreen(),
            routes: [
              GoRoute(
                path: 'language',
                builder: (context, state) => const LanguageSettingsScreen(),
              ),
              GoRoute(
                path: 'help',
                builder: (context, state) => const HelpSupportScreen(),
              ),
              GoRoute(
                path: 'privacy',
                builder: (context, state) => const PrivacySecurityScreen(),
              ),
              GoRoute(
                path: 'about',
                builder: (context, state) => const AboutScreen(),
              ),
              GoRoute(
                path: 'notifications',
                builder: (context, state) => const NotificationsScreen(),
              ),
              GoRoute(
                path: 'owner-help',
                builder: (context, state) => const OwnerHelpSupportScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/owner/analytics',
            builder: (context, state) => const AnalyticsReportsScreen(),
          ),
          GoRoute(
            path: '/owner/reviews',
            builder: (context, state) => const OwnerReviewsScreen(),
          ),
        ],
      ),
      // AI Chat route - now handled as modal in ChatsScreen
    ],
  );
}
