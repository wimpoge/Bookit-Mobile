import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/navigation_utils.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({Key? key}) : super(key: key);

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _biometricEnabled = false;
  bool _twoFactorEnabled = false;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _dataSharing = false;
  bool _analyticsData = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Privacy & Security',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: NavigationUtils.backButton(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Account Security'),
            const SizedBox(height: 16),
            _buildSecurityOption(
              'Change Password',
              'Update your account password',
              Icons.lock_outline,
              () => _showChangePasswordDialog(context),
            ),
            _buildSwitchOption(
              'Biometric Authentication',
              'Use fingerprint or face ID to unlock',
              Icons.fingerprint,
              _biometricEnabled,
              (value) => setState(() => _biometricEnabled = value),
            ),
            _buildSwitchOption(
              'Two-Factor Authentication',
              'Add an extra layer of security',
              Icons.security,
              _twoFactorEnabled,
              (value) => setState(() => _twoFactorEnabled = value),
            ),
            
            const SizedBox(height: 32),
            
            _buildSectionTitle('Privacy Settings'),
            const SizedBox(height: 16),
            _buildSecurityOption(
              'Data & Privacy',
              'Manage your personal data',
              Icons.privacy_tip_outlined,
              () => _showDataPrivacyDialog(context),
            ),
            _buildSwitchOption(
              'Share Data with Partners',
              'Allow data sharing with trusted partners',
              Icons.share_outlined,
              _dataSharing,
              (value) => setState(() => _dataSharing = value),
            ),
            _buildSwitchOption(
              'Analytics & Performance',
              'Help improve the app with usage data',
              Icons.analytics_outlined,
              _analyticsData,
              (value) => setState(() => _analyticsData = value),
            ),
            
            const SizedBox(height: 32),
            
            _buildSectionTitle('Communication Preferences'),
            const SizedBox(height: 16),
            _buildSwitchOption(
              'Email Notifications',
              'Receive booking and promotional emails',
              Icons.email_outlined,
              _emailNotifications,
              (value) => setState(() => _emailNotifications = value),
            ),
            _buildSwitchOption(
              'Push Notifications',
              'Receive notifications on your device',
              Icons.notifications_outlined,
              _pushNotifications,
              (value) => setState(() => _pushNotifications = value),
            ),
            
            const SizedBox(height: 32),
            
            _buildSectionTitle('Account Management'),
            const SizedBox(height: 16),
            _buildSecurityOption(
              'Download My Data',
              'Get a copy of your account data',
              Icons.download_outlined,
              () => _showDownloadDataDialog(context),
            ),
            _buildSecurityOption(
              'Delete Account',
              'Permanently delete your account',
              Icons.delete_outline,
              () => _showDeleteAccountDialog(context),
              isDestructive: true,
            ),
            
            const SizedBox(height: 32),
            
            _buildSectionTitle('Legal'),
            const SizedBox(height: 16),
            _buildSecurityOption(
              'Privacy Policy',
              'Read our privacy policy',
              Icons.policy_outlined,
              () => _showPrivacyPolicy(context),
            ),
            _buildSecurityOption(
              'Terms of Service',
              'Read our terms of service',
              Icons.description_outlined,
              () => _showTermsOfService(context),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSecurityOption(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDestructive 
                ? Colors.red.withOpacity(0.1)
                : Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isDestructive 
                ? Colors.red
                : Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDestructive ? Colors.red : null,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchOption(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Change Password',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: const OutlineInputBorder(),
                labelStyle: GoogleFonts.poppins(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: const OutlineInputBorder(),
                labelStyle: GoogleFonts.poppins(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                border: const OutlineInputBorder(),
                labelStyle: GoogleFonts.poppins(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password updated successfully!'),
                ),
              );
            },
            child: Text('Update', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showDataPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Data & Privacy',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'We collect the following data:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                '• Account information (name, email)\n'
                '• Booking history and preferences\n'
                '• Device information for security\n'
                '• App usage analytics',
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 16),
              Text(
                'Your data is used to:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                '• Provide booking services\n'
                '• Improve app experience\n'
                '• Send important notifications\n'
                '• Ensure account security',
                style: GoogleFonts.poppins(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showDownloadDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Download My Data',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'We\'ll prepare a copy of your data and send it to your registered email address within 30 days.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data export request submitted!'),
                ),
              );
            },
            child: Text('Request', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Account',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
        content: Text(
          'This action cannot be undone. All your data, bookings, and account information will be permanently deleted.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion is not available in demo mode'),
                ),
              );
            },
            child: Text('Delete', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Text(
            'This is a demo privacy policy. In a real app, this would contain detailed information about data collection, usage, and user rights.',
            style: GoogleFonts.poppins(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Terms of Service',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Text(
            'This is a demo terms of service. In a real app, this would contain detailed terms and conditions for using the service.',
            style: GoogleFonts.poppins(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }
}