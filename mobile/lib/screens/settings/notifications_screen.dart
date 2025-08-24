import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/navigation_utils.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Push Notifications
  bool _pushNotifications = true;
  bool _bookingUpdates = true;
  bool _paymentConfirmations = true;
  bool _chatMessages = true;
  bool _promotionalOffers = false;
  
  // Email Notifications
  bool _emailNotifications = true;
  bool _bookingReminders = true;
  bool _weeklyDeals = false;
  bool _monthlyNewsletter = false;
  
  // In-App Notifications
  bool _inAppNotifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  
  // Quiet Hours
  bool _quietHoursEnabled = false;
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 7, minute: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
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
            // Push Notifications Section
            _buildSectionTitle('Push Notifications'),
            const SizedBox(height: 16),
            _buildNotificationCard(
              context,
              [
                _buildSwitchOption(
                  'Push Notifications',
                  'Receive notifications on your device',
                  Icons.notifications_outlined,
                  _pushNotifications,
                  (value) => setState(() => _pushNotifications = value),
                ),
                _buildSwitchOption(
                  'Booking Updates',
                  'Notifications about your booking status',
                  Icons.hotel_outlined,
                  _bookingUpdates,
                  (value) => setState(() => _bookingUpdates = value),
                  enabled: _pushNotifications,
                ),
                _buildSwitchOption(
                  'Payment Confirmations',
                  'Alerts for successful payments',
                  Icons.payment_outlined,
                  _paymentConfirmations,
                  (value) => setState(() => _paymentConfirmations = value),
                  enabled: _pushNotifications,
                ),
                _buildSwitchOption(
                  'Chat Messages',
                  'New messages from hotels',
                  Icons.chat_outlined,
                  _chatMessages,
                  (value) => setState(() => _chatMessages = value),
                  enabled: _pushNotifications,
                ),
                _buildSwitchOption(
                  'Promotional Offers',
                  'Special deals and discounts',
                  Icons.local_offer_outlined,
                  _promotionalOffers,
                  (value) => setState(() => _promotionalOffers = value),
                  enabled: _pushNotifications,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Email Notifications Section
            _buildSectionTitle('Email Notifications'),
            const SizedBox(height: 16),
            _buildNotificationCard(
              context,
              [
                _buildSwitchOption(
                  'Email Notifications',
                  'Receive notifications via email',
                  Icons.email_outlined,
                  _emailNotifications,
                  (value) => setState(() => _emailNotifications = value),
                ),
                _buildSwitchOption(
                  'Booking Reminders',
                  'Reminders about upcoming bookings',
                  Icons.schedule_outlined,
                  _bookingReminders,
                  (value) => setState(() => _bookingReminders = value),
                  enabled: _emailNotifications,
                ),
                _buildSwitchOption(
                  'Weekly Deals',
                  'Best deals of the week',
                  Icons.weekend_outlined,
                  _weeklyDeals,
                  (value) => setState(() => _weeklyDeals = value),
                  enabled: _emailNotifications,
                ),
                _buildSwitchOption(
                  'Monthly Newsletter',
                  'Travel tips and company updates',
                  Icons.article_outlined,
                  _monthlyNewsletter,
                  (value) => setState(() => _monthlyNewsletter = value),
                  enabled: _emailNotifications,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // In-App Settings Section
            _buildSectionTitle('In-App Settings'),
            const SizedBox(height: 16),
            _buildNotificationCard(
              context,
              [
                _buildSwitchOption(
                  'In-App Notifications',
                  'Show notifications within the app',
                  Icons.app_settings_alt_outlined,
                  _inAppNotifications,
                  (value) => setState(() => _inAppNotifications = value),
                ),
                _buildSwitchOption(
                  'Sound',
                  'Play sound for notifications',
                  Icons.volume_up_outlined,
                  _soundEnabled,
                  (value) => setState(() => _soundEnabled = value),
                  enabled: _inAppNotifications,
                ),
                _buildSwitchOption(
                  'Vibration',
                  'Vibrate for notifications',
                  Icons.vibration_outlined,
                  _vibrationEnabled,
                  (value) => setState(() => _vibrationEnabled = value),
                  enabled: _inAppNotifications,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Quiet Hours Section
            _buildSectionTitle('Quiet Hours'),
            const SizedBox(height: 16),
            _buildNotificationCard(
              context,
              [
                _buildSwitchOption(
                  'Quiet Hours',
                  'Disable notifications during specific hours',
                  Icons.bedtime_outlined,
                  _quietHoursEnabled,
                  (value) => setState(() => _quietHoursEnabled = value),
                ),
                if (_quietHoursEnabled) ...[
                  _buildTimeOption(
                    context,
                    'Start Time',
                    'When quiet hours begin',
                    Icons.nightlight_outlined,
                    _quietStart,
                    (time) => setState(() => _quietStart = time),
                  ),
                  _buildTimeOption(
                    context,
                    'End Time',
                    'When quiet hours end',
                    Icons.wb_sunny_outlined,
                    _quietEnd,
                    (time) => setState(() => _quietEnd = time),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Management Section
            _buildSectionTitle('Notification Management'),
            const SizedBox(height: 16),
            _buildNotificationCard(
              context,
              [
                _buildActionOption(
                  context,
                  'Clear All Notifications',
                  'Remove all notifications from history',
                  Icons.clear_all_outlined,
                  () => _showClearNotificationsDialog(context),
                ),
                _buildActionOption(
                  context,
                  'Reset to Default',
                  'Reset all notification settings',
                  Icons.restart_alt_outlined,
                  () => _showResetSettingsDialog(context),
                ),
                _buildActionOption(
                  context,
                  'Notification History',
                  'View your notification history',
                  Icons.history_outlined,
                  () => _showNotificationHistory(context),
                ),
              ],
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

  Widget _buildNotificationCard(BuildContext context, List<Widget> children) {
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
        children: children.asMap().entries.map((entry) {
          final index = entry.key;
          final child = entry.value;
          final isLast = index == children.length - 1;

          return Column(
            children: [
              child,
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

  Widget _buildSwitchOption(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged, {
    bool enabled = true,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: enabled
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: enabled
              ? Theme.of(context).colorScheme.primary
              : Colors.grey,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: enabled
              ? Theme.of(context).colorScheme.onSurface
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      trailing: Switch(
        value: enabled ? value : false,
        onChanged: enabled ? onChanged : null,
      ),
    );
  }

  Widget _buildTimeOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    TimeOfDay time,
    ValueChanged<TimeOfDay> onChanged,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.secondary,
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
      trailing: Text(
        time.format(context),
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      onTap: () async {
        final TimeOfDay? newTime = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (newTime != null) {
          onChanged(newTime);
        }
      },
    );
  }

  Widget _buildActionOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
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

  void _showClearNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear All Notifications',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This will remove all notifications from your history. This action cannot be undone.',
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
                  content: Text('All notifications cleared'),
                ),
              );
            },
            child: Text('Clear', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showResetSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reset Settings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This will reset all notification settings to their default values.',
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
              setState(() {
                _pushNotifications = true;
                _bookingUpdates = true;
                _paymentConfirmations = true;
                _chatMessages = true;
                _promotionalOffers = false;
                _emailNotifications = true;
                _bookingReminders = true;
                _weeklyDeals = false;
                _monthlyNewsletter = false;
                _inAppNotifications = true;
                _soundEnabled = true;
                _vibrationEnabled = true;
                _quietHoursEnabled = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset to default'),
                ),
              );
            },
            child: Text('Reset', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showNotificationHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Notification History',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHistoryItem(
                'Booking Confirmed',
                'Your booking at Grand Hotel has been confirmed',
                '2 hours ago',
              ),
              _buildHistoryItem(
                'New Message',
                'You have a new message from Hotel Paradise',
                '1 day ago',
              ),
              _buildHistoryItem(
                'Payment Successful',
                'Payment of \$250.00 processed successfully',
                '2 days ago',
              ),
              _buildHistoryItem(
                'Special Offer',
                '20% off on weekend bookings!',
                '1 week ago',
              ),
            ],
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

  Widget _buildHistoryItem(String title, String message, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}