import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AuthScreen extends StatefulWidget {
  final bool initiallyShowLogin;

  const AuthScreen({
    Key? key,
    this.initiallyShowLogin = true,
  }) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _tabAnimationController;
  late Animation<double> _tabSlideAnimation;

  // Login form controllers
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _obscureLoginPassword = true;

  // Register form controllers
  final _registerFormKey = GlobalKey<FormState>();
  final _registerEmailController = TextEditingController();
  final _registerUsernameController = TextEditingController();
  final _registerFullNameController = TextEditingController();
  final _registerPhoneController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmPasswordController = TextEditingController();
  bool _obscureRegisterPassword = true;
  bool _obscureRegisterConfirmPassword = true;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initiallyShowLogin ? 0 : 1;
    _pageController = PageController(initialPage: _currentIndex);

    _tabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _tabSlideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _tabAnimationController,
      curve: Curves.easeInOut,
    ));

    if (!widget.initiallyShowLogin) {
      _tabAnimationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabAnimationController.dispose();

    _loginEmailController.dispose();
    _loginPasswordController.dispose();

    _registerEmailController.dispose();
    _registerUsernameController.dispose();
    _registerFullNameController.dispose();
    _registerPhoneController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();

    super.dispose();
  }

  void _switchToLogin() {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _tabAnimationController.reverse();
    }
  }

  void _switchToRegister() {
    if (_currentIndex != 1) {
      setState(() => _currentIndex = 1);
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _tabAnimationController.forward();
    }
  }

  void _handleLogin() {
    if (_loginFormKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(AuthLoginEvent(
            email: _loginEmailController.text.trim(),
            password: _loginPasswordController.text,
          ));
    }
  }

  void _handleRegister() {
    if (_registerFormKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(AuthRegisterEvent(userData: {
            'email': _registerEmailController.text.trim(),
            'username': _registerUsernameController.text.trim(),
            'full_name': _registerFullNameController.text.trim(),
            'phone': _registerPhoneController.text.trim(),
            'password': _registerPasswordController.text,
          }));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is AuthAuthenticated) {
            if (state.user.isOwner) {
              context.go('/owner');
            } else {
              context.go('/home');
            }
          }
        },
        child: SafeArea(
          child: Column(
            children: [
              // Header with logo and tabs
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          'B',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Welcome text
                    Text(
                      'Welcome to BookIt',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Your perfect stay awaits',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Animated Tab buttons
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          // Animated background
                          AnimatedBuilder(
                            animation: _tabSlideAnimation,
                            builder: (context, child) {
                              final containerWidth =
                                  (MediaQuery.of(context).size.width - 48) /
                                      2; // Account for padding
                              return Positioned(
                                left: _tabSlideAnimation.value * containerWidth,
                                top: 2,
                                bottom: 2,
                                width: containerWidth,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(
                                          _currentIndex == 0 ? 10 : 2),
                                      bottomLeft: Radius.circular(
                                          _currentIndex == 0 ? 10 : 2),
                                      topRight: Radius.circular(
                                          _currentIndex == 1 ? 10 : 2),
                                      bottomRight: Radius.circular(
                                          _currentIndex == 1 ? 10 : 2),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          // Tab buttons
                          Row(
                            children: [
                              Expanded(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _switchToLogin,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      bottomLeft: Radius.circular(12),
                                    ),
                                    child: Container(
                                      height: 50,
                                      child: Center(
                                        child: Text(
                                          'Sign In',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            color: _currentIndex == 0
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _switchToRegister,
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                    child: Container(
                                      height: 50,
                                      child: Center(
                                        child: Text(
                                          'Sign Up',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            color: _currentIndex == 1
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // PageView for forms
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                    if (index == 0) {
                      _tabAnimationController.reverse();
                    } else {
                      _tabAnimationController.forward();
                    }
                  },
                  children: [
                    _buildLoginForm(),
                    _buildRegisterForm(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),

            Text(
              'Email',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _loginEmailController,
              hintText: 'Enter your email',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please fill out this field.';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value!)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            Text(
              'Password',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _loginPasswordController,
              hintText: 'Enter your password',
              obscureText: _obscureLoginPassword,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureLoginPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscureLoginPassword = !_obscureLoginPassword;
                  });
                },
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please fill out this field.';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Forgot password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // TODO: Implement forgot password
                },
                child: Text(
                  'Forgot password?',
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Sign In button
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                return CustomButton(
                  text: 'Sign In',
                  onPressed: _handleLogin,
                  isLoading: state is AuthLoading,
                  icon: Icons.arrow_forward,
                );
              },
            ),

            const SizedBox(height: 32),

            // Social login section
            _buildSocialLoginSection(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _registerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),

            Text(
              'Email',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _registerEmailController,
              hintText: 'Enter your email',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please fill out this field.';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value!)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            Text(
              'Username',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _registerUsernameController,
              hintText: 'Enter your username',
              prefixIcon: const Icon(Icons.person_outline),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please fill out this field.';
                }
                if (value!.length < 3) {
                  return 'Username must be at least 3 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            Text(
              'Full Name',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _registerFullNameController,
              hintText: 'Enter your full name',
              prefixIcon: const Icon(Icons.badge_outlined),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please fill out this field.';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            Text(
              'Phone',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _registerPhoneController,
              hintText: 'Enter your phone number',
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(Icons.phone_outlined),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please fill out this field.';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            Text(
              'Password',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _registerPasswordController,
              hintText: 'Enter your password',
              obscureText: _obscureRegisterPassword,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureRegisterPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscureRegisterPassword = !_obscureRegisterPassword;
                  });
                },
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please fill out this field.';
                }
                if (value!.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            Text(
              'Confirm Password',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _registerConfirmPasswordController,
              hintText: 'Confirm your password',
              obscureText: _obscureRegisterConfirmPassword,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureRegisterConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscureRegisterConfirmPassword =
                        !_obscureRegisterConfirmPassword;
                  });
                },
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please fill out this field.';
                }
                if (value != _registerPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Sign Up button
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                return CustomButton(
                  text: 'Sign Up',
                  onPressed: _handleRegister,
                  isLoading: state is AuthLoading,
                  icon: Icons.arrow_forward,
                );
              },
            ),

            const SizedBox(height: 32),

            // Social login section
            _buildSocialLoginSection(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLoginSection() {
    return Column(
      children: [
        // Or continue with
        Row(
          children: [
            Expanded(child: Divider(color: Theme.of(context).dividerColor)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Or continue with',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
            Expanded(child: Divider(color: Theme.of(context).dividerColor)),
          ],
        ),

        const SizedBox(height: 24),

        // Social buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement Google sign in/up
                },
                icon: const Icon(Icons.g_mobiledata, size: 24),
                label: const Text('Google'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement Facebook sign in/up
                },
                icon: const Icon(Icons.facebook, size: 24),
                label: const Text('Facebook'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
