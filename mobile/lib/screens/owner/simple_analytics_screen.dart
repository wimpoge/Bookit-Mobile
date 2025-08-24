import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/navigation_utils.dart';

class SimpleAnalyticsScreen extends StatelessWidget {
  const SimpleAnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Analytics & Reports',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: NavigationUtils.backButton(context),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 64),
            SizedBox(height: 16),
            Text('Analytics Screen is Working!'),
            SizedBox(height: 8),
            Text('The full analytics implementation is available.'),
          ],
        ),
      ),
    );
  }
}