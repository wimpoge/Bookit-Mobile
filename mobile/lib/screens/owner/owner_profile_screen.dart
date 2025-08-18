import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/theme/theme_bloc.dart';
import '../../models/user.dart';
import '../../widgets/edit_profile_bottom_sheet.dart';

class OwnerProfileScreen extends StatelessWidget {
  const OwnerProfileScreen({Key? key}) : super(key: key);

  void _showEditProfileBottomSheet(BuildContext context, User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditProfileBottomSheet(user: user),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Logout',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthBloc>().add(AuthLogoutEvent());
            },
            child: Text(
              'Logout',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Owner Profile',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _showEditProfileBottomSheet(context, state.user),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return _buildProfileContent(context, state.user);
          } else if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return const Center(
              child: Text('Please login to view profile'),
            );
          }
        },
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, User user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile header
          _buildProfileHeader(context, user),
          
          const SizedBox(height: 32),
          
          // Business stats
          _buildBusinessStats(context),
          
          const SizedBox(height: 32),
          
          // Settings sections
          _buildSettingsSections(context),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, User user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
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
          // Profile picture
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white.withOpacity(0.2),
                backgroundImage: user.profileImage != null
                    ? NetworkImage(user.profileImage!)
                    : null,
                child: user.profileImage == null
                    ? Text(
                        user.fullName?.split(' ').map((n) => n[0]).take(2).join() ?? 'O',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.business,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // User info
          Text(
            user.fullName ?? 'Hotel Owner',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            user.email,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Owner badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_user,
                  size: 16,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Verified Hotel Owner',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.hotel,
            title: 'Hotels',
            subtitle: '5',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.book_online,
            title: 'Bookings',
            subtitle: '127',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.attach_money,
            title: 'Revenue',
            subtitle: '\$15.2K',
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSections(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Business Management
        _buildSectionTitle('Business Management'),
        const SizedBox(height: 12),
        _buildSettingsGroup(context, [
          OwnerSettingsItem(
            icon: Icons.hotel_outlined,
            title: 'Manage Hotels',
            subtitle: 'Add, edit, and manage your properties',
            onTap: () {
              // Already handled by navigation
            },
          ),
          OwnerSettingsItem(
            icon: Icons.analytics_outlined,
            title: 'Analytics & Reports',
            subtitle: 'View performance metrics',
            onTap: () {
              // TODO: Navigate to analytics
            },
          ),
          OwnerSettingsItem(
            icon: Icons.payment_outlined,
            title: 'Earnings',
            subtitle: 'Track your revenue and payouts',
            onTap: () {
              // TODO: Navigate to earnings
            },
          ),
        ]),
        
        const SizedBox(height: 24),
        
        // Account Settings
        _buildSectionTitle('Account Settings'),
        const SizedBox(height: 12),
        _buildSettingsGroup(context, [
          OwnerSettingsItem(
            icon: Icons.person_outline,
            title: 'Business Information',
            subtitle: 'Update your business details',
            onTap: () {
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthAuthenticated) {
                _showEditProfileBottomSheet(context, authState.user);
              }
            },
          ),
          OwnerSettingsItem(
            icon: Icons.security_outlined,
            title: 'Security',
            subtitle: 'Password and security settings',
            onTap: () {
              // TODO: Navigate to security settings
            },
          ),
          OwnerSettingsItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage booking and guest notifications',
            onTap: () {
              // TODO: Navigate to notifications
            },
          ),
        ]),
        
        const SizedBox(height: 24),
        
        // App Settings
        _buildSectionTitle('App Settings'),
        const SizedBox(height: 12),
        BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            return _buildSettingsGroup(context, [
              OwnerSettingsItem(
                icon: themeState.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                title: 'Dark Mode',
                subtitle: themeState.isDarkMode ? 'Enabled' : 'Disabled',
                trailing: Switch(
                  value: themeState.isDarkMode,
                  onChanged: (value) {
                    context.read<ThemeBloc>().add(ThemeToggleEvent());
                  },
                ),
                onTap: () {
                  context.read<ThemeBloc>().add(ThemeToggleEvent());
                },
              ),
              OwnerSettingsItem(
                icon: Icons.language_outlined,
                title: 'Language & Region',
                subtitle: 'English (US)',
                onTap: () {
                  // TODO: Navigate to language settings
                },
              ),
            ]);
          },
        ),
        
        const SizedBox(height: 24),
        
        // Support & Legal
        _buildSectionTitle('Support & Legal'),
        const SizedBox(height: 12),
        _buildSettingsGroup(context, [
          OwnerSettingsItem(
            icon: Icons.help_outline,
            title: 'Owner Support',
            subtitle: 'Get help with your business account',
            onTap: () {
              // TODO: Navigate to owner support
            },
          ),
          OwnerSettingsItem(
            icon: Icons.article_outlined,
            title: 'Terms of Service',
            subtitle: 'Business terms and conditions',
            onTap: () {
              // TODO: Navigate to terms
            },
          ),
          OwnerSettingsItem(
            icon: Icons.policy_outlined,
            title: 'Privacy Policy',
            subtitle: 'How we handle your business data',
            onTap: () {
              // TODO: Navigate to privacy policy
            },
          ),
        ]),
        
        const SizedBox(height: 32),
        
        // Logout button
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(Icons.logout, color: Colors.red, size: 32),
              const SizedBox(height: 8),
              Text(
                'Logout',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sign out of your business account',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.red.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showLogoutDialog(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Logout',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, List<OwnerSettingsItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;
          
          return Column(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item.icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  item.title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  item.subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                trailing: item.trailing ?? Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
                onTap: item.onTap,
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 68,
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class OwnerSettingsItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  OwnerSettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });
}