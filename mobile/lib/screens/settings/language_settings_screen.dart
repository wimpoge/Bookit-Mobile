import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({Key? key}) : super(key: key);

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _selectedLanguage = 'en';

  final List<LanguageOption> _languages = [
    LanguageOption(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      region: 'United States',
      flagIcon: '🇺🇸',
    ),
    LanguageOption(
      code: 'id',
      name: 'Indonesian',
      nativeName: 'Bahasa Indonesia',
      region: 'Indonesia',
      flagIcon: '🇮🇩',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // TODO: Load saved language preference
    _selectedLanguage = 'en';
  }

  void _selectLanguage(String languageCode) {
    setState(() {
      _selectedLanguage = languageCode;
    });
    // TODO: Save language preference and update app locale
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Language & Region',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.language,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Choose Your Language',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select your preferred language and region. This will change the app\'s interface language and regional settings.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Language options
            Text(
              'Available Languages',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            
            const SizedBox(height: 16),

            Container(
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
                children: _languages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final language = entry.value;
                  final isSelected = _selectedLanguage == language.code;
                  final isLast = index == _languages.length - 1;

                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              language.flagIcon,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        title: Text(
                          language.name,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              language.nativeName,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                              ),
                            ),
                            Text(
                              language.region,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                        trailing: isSelected
                            ? Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  size: 16,
                                ),
                              )
                            : Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outline
                                        .withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                              ),
                        onTap: () => _selectLanguage(language.code),
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          indent: 90,
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Additional info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'About Language Settings',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Changing the language will update all app content\n• Regional settings affect date, time, and currency formats\n• App will restart to apply changes',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Apply button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Show confirmation and apply changes
                  _showConfirmationDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'Apply Language Settings',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialog() {
    final selectedLang = _languages.firstWhere((lang) => lang.code == _selectedLanguage);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Apply Language Settings?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Change language to ${selectedLang.name} (${selectedLang.nativeName})?\n\nThe app will restart to apply changes.',
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
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Save language preference and restart app
              _applyLanguageChange();
            },
            child: Text(
              'Apply',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _applyLanguageChange() {
    // TODO: Implement language change logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Language updated successfully!',
          style: GoogleFonts.poppins(),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
    Navigator.of(context).pop();
  }
}

class LanguageOption {
  final String code;
  final String name;
  final String nativeName;
  final String region;
  final String flagIcon;

  LanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.region,
    required this.flagIcon,
  });
}