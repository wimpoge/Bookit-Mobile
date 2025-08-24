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

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _tabAnimationController;
  late Animation<double> _tabSlideAnimation;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initiallyShowLogin ? 0 : 1;
    _pageController = PageController(initialPage: _currentIndex);

    _tabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _tabSlideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _tabAnimationController,
      curve: Curves.fastOutSlowIn,
    ));

    if (!widget.initiallyShowLogin) {
      _tabAnimationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabAnimationController.dispose();
    super.dispose();
  }

  void _switchToLogin() {
    if (_currentIndex != 0) {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  void _switchToRegister() {
    if (_currentIndex != 1) {
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.fastOutSlowIn,
      );
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

                    // Optimized Tab Selector
                    _buildTabSelector(),
                  ],
                ),
              ),

              // PageView with form widgets
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    if (_currentIndex != index) {
                      setState(() => _currentIndex = index);
                      if (index == 0) {
                        _tabAnimationController.reverse();
                      } else {
                        _tabAnimationController.forward();
                      }
                    }
                  },
                  physics: const ClampingScrollPhysics(),
                  children: const [
                    LoginFormWidget(),
                    RegisterFormWidget(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Smooth animated background
          AnimatedBuilder(
            animation: _tabSlideAnimation,
            builder: (context, child) {
              final containerWidth = (MediaQuery.of(context).size.width - 48) / 2;
              return AnimatedPositioned(
                duration: Duration.zero, // Use animation controller instead
                left: _tabSlideAnimation.value * containerWidth,
                top: 3,
                bottom: 3,
                width: containerWidth - 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Tab buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _switchToLogin,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: _currentIndex == 0
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                        child: const Text('Sign In'),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _switchToRegister,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: _currentIndex == 1
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                        child: const Text('Sign Up'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Extracted Login Form Widget
class LoginFormWidget extends StatefulWidget {
  const LoginFormWidget({Key? key}) : super(key: key);

  @override
  State<LoginFormWidget> createState() => _LoginFormWidgetState();
}

class _LoginFormWidgetState extends State<LoginFormWidget> with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(AuthLoginEvent(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey,
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
              controller: _emailController,
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
              controller: _passwordController,
              hintText: 'Enter your password',
              obscureText: _obscurePassword,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
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

  Widget _buildSocialLoginSection() {
    return Column(
      children: [
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
        Row(
          children: [
            Expanded(
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return OutlinedButton.icon(
                    onPressed: state is AuthLoading ? null : () {
                      context.read<AuthBloc>().add(AuthGoogleLoginEvent());
                    },
                    icon: const Icon(Icons.g_mobiledata, size: 24),
                    label: const Text('Google'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
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

// Extracted Register Form Widget
class RegisterFormWidget extends StatefulWidget {
  const RegisterFormWidget({Key? key}) : super(key: key);

  @override
  State<RegisterFormWidget> createState() => _RegisterFormWidgetState();
}

class _RegisterFormWidgetState extends State<RegisterFormWidget> with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(AuthRegisterEvent(userData: {
            'email': _emailController.text.trim(),
            'username': _usernameController.text.trim(),
            'full_name': _fullNameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'password': _passwordController.text,
          }));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey,
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
              controller: _emailController,
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
              controller: _usernameController,
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
              controller: _fullNameController,
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
              controller: _phoneController,
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
              controller: _passwordController,
              hintText: 'Enter your password',
              obscureText: _obscurePassword,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
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
              controller: _confirmPasswordController,
              hintText: 'Confirm your password',
              obscureText: _obscureConfirmPassword,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please fill out this field.';
                }
                if (value != _passwordController.text) {
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
        Row(
          children: [
            Expanded(
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return OutlinedButton.icon(
                    onPressed: state is AuthLoading ? null : () {
                      context.read<AuthBloc>().add(AuthGoogleLoginEvent());
                    },
                    icon: const Icon(Icons.g_mobiledata, size: 24),
                    label: const Text('Google'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
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
