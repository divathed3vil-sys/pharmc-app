import 'package:flutter/material.dart';
import '../../services/preferences_service.dart';
import '../home_screen.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);

    Widget langTile({
      required String title,
      required String subtitle,
      required bool enabled,
      required VoidCallback? onTap,
    }) {
      return Opacity(
        opacity: enabled ? 1.0 : 0.45,
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: enabled
                    ? Colors.teal.shade600
                    : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: subtextColor),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              'Choose Language',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sinhala and Tamil will be added later.',
              style: TextStyle(fontSize: 14, color: subtextColor),
            ),
            const SizedBox(height: 20),

            langTile(
              title: 'English',
              subtitle: 'Available',
              enabled: true,
              onTap: () async {
                await PreferencesService.setLanguage('en');
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                }
              },
            ),
            langTile(
              title: 'සිංහල',
              subtitle: 'Coming soon',
              enabled: false,
              onTap: null,
            ),
            langTile(
              title: 'தமிழ்',
              subtitle: 'Coming soon',
              enabled: false,
              onTap: null,
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}
