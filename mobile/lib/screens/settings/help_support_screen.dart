import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/navigation_utils.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Help & Support',
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
            _buildSectionTitle('Frequently Asked Questions'),
            const SizedBox(height: 16),
            _buildFAQItem(
              context,
              'How do I book a hotel?',
              'Browse hotels, select your preferred one, choose dates, and complete the booking process.',
            ),
            _buildFAQItem(
              context,
              'Can I cancel my booking?',
              'Yes, you can cancel your booking up to 24 hours before check-in for a full refund.',
            ),
            _buildFAQItem(
              context,
              'How do I contact a hotel?',
              'Use the chat feature in the hotel details or booking screen to communicate directly with the hotel.',
            ),
            _buildFAQItem(
              context,
              'What payment methods are accepted?',
              'We accept all major credit cards, debit cards, and digital payment methods.',
            ),
            _buildFAQItem(
              context,
              'How do I add photos to my hotel listing?',
              'As a hotel owner, go to your hotel management section and use the image upload feature.',
            ),
            
            const SizedBox(height: 32),
            
            _buildSectionTitle('Contact Support'),
            const SizedBox(height: 16),
            _buildContactItem(
              context,
              Icons.email,
              'Email Support',
              'support@bookit.com',
              () => _launchEmail('support@bookit.com'),
            ),
            _buildContactItem(
              context,
              Icons.phone,
              'Phone Support',
              '+1 (555) 123-4567',
              () => _launchPhone('+15551234567'),
            ),
            _buildContactItem(
              context,
              Icons.chat,
              'Live Chat',
              'Available 24/7',
              () => _showLiveChatDialog(context),
            ),
            
            const SizedBox(height: 32),
            
            _buildSectionTitle('Resources'),
            const SizedBox(height: 16),
            _buildResourceItem(
              context,
              Icons.book,
              'User Guide',
              'Learn how to use all features',
              () => _showUserGuide(context),
            ),
            _buildResourceItem(
              context,
              Icons.video_library,
              'Video Tutorials',
              'Watch step-by-step guides',
              () => _showVideoTutorials(context),
            ),
            _buildResourceItem(
              context,
              Icons.feedback,
              'Send Feedback',
              'Help us improve the app',
              () => _showFeedbackDialog(context),
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

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          question,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
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
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  Widget _buildResourceItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.secondary,
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
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=BookIt Support Request',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  void _showLiveChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Live Chat',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Live chat feature is coming soon! For now, please use email or phone support.',
          style: GoogleFonts.poppins(),
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

  void _showUserGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'User Guide',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'User guide is coming soon! Check back later for comprehensive guides.',
          style: GoogleFonts.poppins(),
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

  void _showVideoTutorials(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Video Tutorials',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Video tutorials are coming soon! We\'ll have step-by-step guides for all features.',
          style: GoogleFonts.poppins(),
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

  void _showFeedbackDialog(BuildContext context) {
    final TextEditingController feedbackController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Send Feedback',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'We\'d love to hear your thoughts!',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter your feedback here...',
                border: const OutlineInputBorder(),
                hintStyle: GoogleFonts.poppins(),
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
                  content: Text('Thank you for your feedback!'),
                ),
              );
            },
            child: Text('Send', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }
}