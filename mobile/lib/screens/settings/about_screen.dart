import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/navigation_utils.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'About',
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
          children: [
            // App Icon and Name
            _buildAppHeader(context),
            
            const SizedBox(height: 32),
            
            // App Information
            _buildAppInfo(context),
            
            const SizedBox(height: 32),
            
            // Company Information
            _buildCompanyInfo(context),
            
            const SizedBox(height: 32),
            
            // Links Section
            _buildLinksSection(context),
            
            const SizedBox(height: 32),
            
            // Legal Section
            _buildLegalSection(context),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAppHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // App Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.hotel,
              size: 40,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // App Name
          Text(
            'BookIt',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Version
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Version 1.0.0',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About BookIt',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'BookIt is your ultimate hotel booking companion. We make it easy to find, book, and manage your hotel reservations with a seamless and intuitive experience.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Features:',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildFeatureItem('🏨 Browse and book hotels worldwide'),
          _buildFeatureItem('💬 Direct chat with hotel owners'),
          _buildFeatureItem('📱 Real-time booking management'),
          _buildFeatureItem('🔒 Secure payments and data protection'),
          _buildFeatureItem('🌙 Dark mode support'),
          _buildFeatureItem('🌍 Multi-language support'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        feature,
        style: GoogleFonts.poppins(
          fontSize: 14,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildCompanyInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Company Information',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.business, 'BookIt Technologies Inc.'),
          _buildInfoRow(Icons.location_on, 'San Francisco, CA, USA'),
          _buildInfoRow(Icons.email, 'contact@bookit.com'),
          _buildInfoRow(Icons.phone, '+1 (555) 123-4567'),
          _buildInfoRow(Icons.language, 'www.bookit.com'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinksSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Follow Us',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildLinkItem(
            context,
            Icons.web,
            'Website',
            'Visit our website',
            () => _launchUrl('https://bookit.com'),
          ),
          _buildLinkItem(
            context,
            Icons.facebook,
            'Facebook',
            'Follow us on Facebook',
            () => _launchUrl('https://facebook.com/bookit'),
          ),
          _buildLinkItem(
            context,
            Icons.alternate_email,
            'Twitter',
            'Follow us on Twitter',
            () => _launchUrl('https://twitter.com/bookit'),
          ),
          _buildLinkItem(
            context,
            Icons.camera_alt,
            'Instagram',
            'Follow us on Instagram',
            () => _launchUrl('https://instagram.com/bookit'),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildLegalSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legal Information',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildLinkItem(
            context,
            Icons.policy,
            'Privacy Policy',
            'View our privacy policy',
            () => _showPrivacyPolicy(context),
          ),
          _buildLinkItem(
            context,
            Icons.description,
            'Terms of Service',
            'View our terms of service',
            () => _showTermsOfService(context),
          ),
          _buildLinkItem(
            context,
            Icons.gavel,
            'Licenses',
            'View open source licenses',
            () => _showLicenses(context),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '© 2024 BookIt Technologies Inc.\nAll rights reserved.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
            'This is a demo privacy policy. In a real app, this would contain detailed information about how we collect, use, and protect your personal data.',
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
            'This is a demo terms of service. In a real app, this would contain detailed terms and conditions for using our service.',
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

  void _showLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'BookIt',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 BookIt Technologies Inc.',
    );
  }
}