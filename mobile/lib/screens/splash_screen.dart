import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../blocs/auth/auth_bloc.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _loadingController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _loadingAnimation;

  @override
  void initState() {
    super.initState();

    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Loading animation controller
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Logo scale animation
    _logoScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    // Logo opacity animation
    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    // Loading dots animation
    _loadingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    // Start logo animation
    _logoController.forward();

    // Wait a bit then start loading animation
    await Future.delayed(const Duration(milliseconds: 800));
    _loadingController.repeat();

    // Check auth state and navigate after splash
    await Future.delayed(const Duration(milliseconds: 2500));
    _checkAuthAndNavigate();
  }

  void _checkAuthAndNavigate() async {
    print('SplashScreen: Checking auth state and navigating...');
    
    // Trigger auth check now that UI is ready
    context.read<AuthBloc>().add(AuthCheckStatusEvent());
    
    // Listen for auth state changes
    final authBloc = context.read<AuthBloc>();
    await for (final authState in authBloc.stream) {
      print('SplashScreen: Auth state changed to ${authState.runtimeType}');
      
      if (authState is AuthAuthenticated) {
        print('SplashScreen: User authenticated, navigating...');
        if (authState.user.isOwner) {
          context.go('/owner/hotels');
        } else {
          context.go('/home');
        }
        break;
      } else if (authState is AuthUnauthenticated) {
        print('SplashScreen: User not authenticated, going to auth screen');
        context.go('/auth');
        break;
      } else if (authState is AuthError) {
        print('SplashScreen: Auth error, going to auth screen');
        context.go('/auth');
        break;
      }
      // Continue listening if state is AuthLoading
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E5984), // Your logo's blue background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with animations
            AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _logoScaleAnimation.value,
                  child: Opacity(
                    opacity: _logoOpacityAnimation.value,
                    child: Container(
                      width: 280,
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 60),

            // Loading animation
            AnimatedBuilder(
              animation: _loadingAnimation,
              builder: (context, child) {
                return Column(
                  children: [
                    // Loading text
                    Text(
                      'Loading...',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    
                    const SizedBox(height: 20),

                    // Loading dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(
                              0.3 + 
                              (0.7 * 
                                (((_loadingAnimation.value + (index * 0.2)) % 1.0).clamp(0.0, 1.0))
                              )
                            ),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 30),

                    // Progress bar
                    Container(
                      width: 200,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _logoController.value,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 80),

            // App subtitle
            AnimatedBuilder(
              animation: _logoOpacityAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _logoOpacityAnimation.value * 0.7,
                  child: Text(
                    'Your perfect stay awaits',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.8),
                      letterSpacing: 0.5,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}