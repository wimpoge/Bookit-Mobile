import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import 'config/app_router.dart';
import 'config/theme.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/theme/theme_bloc.dart';
import 'blocs/hotels/hotels_bloc.dart';
import 'blocs/bookings/bookings_bloc.dart';
import 'blocs/payments/payments_bloc.dart';
import 'blocs/reviews/reviews_bloc.dart';
import 'blocs/chat/chat_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  final apiService = ApiService();
  final authService = AuthService(apiService, prefs);
  
  runApp(HotelBookingApp(
    authService: authService,
    apiService: apiService,
    prefs: prefs,
  ));
}

class HotelBookingApp extends StatelessWidget {
  final AuthService authService;
  final ApiService apiService;
  final SharedPreferences prefs;

  const HotelBookingApp({
    Key? key,
    required this.authService,
    required this.apiService,
    required this.prefs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>(
          create: (context) => ThemeBloc(prefs)..add(ThemeLoadEvent()),
        ),
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(authService)..add(AuthCheckStatusEvent()),
        ),
        BlocProvider<HotelsBloc>(
          create: (context) => HotelsBloc(apiService),
        ),
        BlocProvider<BookingsBloc>(
          create: (context) => BookingsBloc(apiService),
        ),
        BlocProvider<PaymentsBloc>(
          create: (context) => PaymentsBloc(apiService),
        ),
        BlocProvider<ReviewsBloc>(
          create: (context) => ReviewsBloc(apiService),
        ),
        BlocProvider<ChatBloc>(
          create: (context) => ChatBloc(apiService),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp.router(
            title: 'BookIt',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}