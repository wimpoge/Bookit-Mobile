import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/navigation_utils.dart';

class OwnerHelpSupportScreen extends StatelessWidget {
  const OwnerHelpSupportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Owner Support',
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
            _buildSectionTitle('Business Account FAQs'),
            const SizedBox(height: 16),
            _buildFAQItem(
              context,
              'How do I add my hotel to BookIt?',
              'Go to your Hotels section, tap the + button, and fill out your property details including photos, amenities, and pricing.',
            ),
            _buildFAQItem(
              context,
              'How do I manage booking requests?',
              'All booking requests appear in your Bookings section. You can accept, decline, or request modifications before confirming.',
            ),
            _buildFAQItem(
              context,
              'How do pricing and commissions work?',
              'You set your own room rates. BookIt charges a 10% commission on confirmed bookings, deducted from your payouts.',
            ),
            _buildFAQItem(
              context,
              'When do I receive payments?',
              'Payments are processed weekly for completed stays. Funds are transferred to your registered bank account within 5-7 business days.',
            ),
            _buildFAQItem(
              context,
              'How do I handle guest communications?',
              'Use the built-in chat feature to communicate directly with guests. All conversations are logged for your reference.',
            ),
            _buildFAQItem(
              context,
              'What if I need to cancel a confirmed booking?',
              'Contact our owner support team immediately. Cancellations may result in penalties and affect your property\'s ranking.',
            ),
            
            const SizedBox(height: 32),
            
            _buildSectionTitle('Owner Support'),
            const SizedBox(height: 16),
            _buildContactItem(
              context,
              Icons.headset_mic,
              'Owner Success Manager',
              'Dedicated support for business accounts',
              () => _launchPhone('+15551234568'),
            ),
            _buildContactItem(
              context,
              Icons.email,
              'Owner Support Email',
              'owners@bookit.com',
              () => _launchEmail('owners@bookit.com'),
            ),
            _buildContactItem(
              context,
              Icons.chat_bubble,
              'Priority Chat Support',
              'Available 24/7 for business accounts',
              () => _showPriorityChat(context),
            ),
            _buildContactItem(
              context,
              Icons.video_call,
              'Schedule Video Call',
              'Book a consultation with our team',
              () => _scheduleVideoCall(context),
            ),
            
            const SizedBox(height: 32),
            
            _buildSectionTitle('Business Resources'),
            const SizedBox(height: 16),
            _buildResourceItem(
              context,
              Icons.trending_up,
              'Revenue Optimization Guide',
              'Tips to maximize your earnings',
              () => _showRevenueGuide(context),
            ),
            _buildResourceItem(
              context,
              Icons.photo_camera,
              'Property Photography Tips',
              'Best practices for hotel photos',
              () => _showPhotographyTips(context),
            ),
            _buildResourceItem(
              context,
              Icons.star_rate,
              'Guest Experience Best Practices',
              'How to improve ratings and reviews',
              () => _showExperienceGuide(context),
            ),
            _buildResourceItem(
              context,
              Icons.assessment,
              'Analytics Dashboard Guide',
              'Understanding your performance metrics',
              () => _showAnalyticsGuide(context),
            ),
            _buildResourceItem(
              context,
              Icons.account_balance,
              'Tax & Legal Resources',
              'Important information for hotel owners',
              () => _showTaxResources(context),
            ),
            
            const SizedBox(height: 32),
            
            _buildSectionTitle('Technical Support'),
            const SizedBox(height: 16),
            _buildResourceItem(
              context,
              Icons.bug_report,
              'Report a Bug',
              'Technical issues with the app',
              () => _reportBug(context),
            ),
            _buildResourceItem(
              context,
              Icons.feedback,
              'Feature Request',
              'Suggest improvements for owners',
              () => _featureRequest(context),
            ),
            _buildResourceItem(
              context,
              Icons.api,
              'API Documentation',
              'For advanced integrations',
              () => _launchUrl('https://api.bookit.com/docs'),
            ),
            
            const SizedBox(height: 32),
            
            _buildSectionTitle('Community'),
            const SizedBox(height: 16),
            _buildResourceItem(
              context,
              Icons.group,
              'Owner Community Forum',
              'Connect with other hotel owners',
              () => _launchUrl('https://community.bookit.com/owners'),
            ),
            _buildResourceItem(
              context,
              Icons.event,
              'Owner Webinars',
              'Monthly training sessions',
              () => _showWebinars(context),
            ),
            _buildResourceItem(
              context,
              Icons.email_outlined,
              'Owner Newsletter',
              'Industry insights and updates',
              () => _subscribeNewsletter(context),
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
      query: 'subject=BookIt Owner Support Request',
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

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showPriorityChat(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Priority Chat Support',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Priority chat support is available for business accounts. You will be connected to a specialist within 2 minutes.',
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
                  content: Text('Connecting you to priority support...'),
                ),
              );
            },
            child: Text('Connect Now', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _scheduleVideoCall(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Schedule Video Consultation',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Book a one-on-one video consultation with our owner success team to optimize your property performance.',
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
              _launchUrl('https://calendly.com/bookit-owner-success');
            },
            child: Text('Schedule', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showRevenueGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Revenue Optimization',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Text(
            '• Optimize pricing based on demand patterns\n'
            '• Use high-quality photos to increase bookings\n'
            '• Respond quickly to guest messages\n'
            '• Maintain consistently high ratings\n'
            '• Offer competitive amenities\n'
            '• Update availability calendar regularly\n'
            '• Use dynamic pricing tools\n'
            '• Promote during peak seasons',
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

  void _showPhotographyTips(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Photography Best Practices',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Text(
            '• Use natural lighting when possible\n'
            '• Take photos from multiple angles\n'
            '• Ensure rooms are clean and tidy\n'
            '• Highlight unique features and amenities\n'
            '• Use high-resolution images (min 1080p)\n'
            '• Include exterior and common areas\n'
            '• Show the neighborhood and nearby attractions\n'
            '• Update photos regularly',
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

  void _showExperienceGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Guest Experience Tips',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Text(
            '• Respond to messages within 1 hour\n'
            '• Provide clear check-in instructions\n'
            '• Welcome guests personally when possible\n'
            '• Keep property descriptions accurate\n'
            '• Address issues promptly and professionally\n'
            '• Follow up after checkout\n'
            '• Ask for reviews from satisfied guests\n'
            '• Learn from negative feedback',
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

  void _showAnalyticsGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Understanding Analytics',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Text(
            '• Revenue trends show earning patterns\n'
            '• Occupancy rate indicates demand\n'
            '• Guest ratings affect search ranking\n'
            '• Booking sources show marketing effectiveness\n'
            '• Seasonal data helps plan pricing\n'
            '• Compare performance with competitors\n'
            '• Use data to make informed decisions\n'
            '• Export reports for tax purposes',
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

  void _showTaxResources(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Tax & Legal Information',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Text(
            'Important: Consult with tax professionals for specific advice.\n\n'
            '• Keep detailed records of all transactions\n'
            '• Understand local hotel tax requirements\n'
            '• Track business expenses for deductions\n'
            '• Maintain insurance coverage\n'
            '• Follow local zoning and permit laws\n'
            '• Issue proper receipts to guests\n'
            '• Report income accurately\n'
            '• Consider business entity structure',
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

  void _reportBug(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Report Bug',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Help us improve by reporting bugs or technical issues.',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe the issue you encountered...',
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
                  content: Text('Bug report submitted. Thank you!'),
                ),
              );
            },
            child: Text('Submit', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _featureRequest(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Feature Request',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'What feature would help improve your business?',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe your feature request...',
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
                  content: Text('Feature request submitted!'),
                ),
              );
            },
            child: Text('Submit', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showWebinars(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Owner Webinars',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upcoming Webinars:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text('• Revenue Optimization Strategies - Feb 15, 2024'),
              Text('• Guest Communication Best Practices - Feb 22, 2024'),
              Text('• Photography Workshop - Mar 1, 2024'),
              Text('• Tax Season Preparation - Mar 8, 2024'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _launchUrl('https://webinars.bookit.com/owners');
            },
            child: Text('Register', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _subscribeNewsletter(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Owner Newsletter',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Stay updated with industry insights, platform updates, and success stories from fellow owners.',
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
                  content: Text('Subscribed to owner newsletter!'),
                ),
              );
            },
            child: Text('Subscribe', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }
}