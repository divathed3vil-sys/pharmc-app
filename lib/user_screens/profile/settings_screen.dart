import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/preferences_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _darkMode = 'system';
  String _uiScale = 'normal';
  bool _notifications = true;
  String _language = 'en';

  @override
  void initState() {
    super.initState();
    _darkMode = PreferencesService.getDarkMode();
    _uiScale = PreferencesService.getUiScale();
    _notifications = PreferencesService.getNotificationsEnabled();
    _language = PreferencesService.getLanguage();
  }

  void _applyThemeChange() {
    MyApp.refresh(context);
  }

  @override
  Widget build(BuildContext context) {
    // Get current theme colors dynamically
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFF8F9FA);
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final Color subtextColor = isDark
        ? Colors.grey.shade400
        : Colors.grey.shade500;
    final Color iconBgColor = isDark
        ? Colors.teal.shade900
        : Colors.teal.shade50;
    final Color selectorBg = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final Color selectorBorder = isDark
        ? Colors.grey.shade700
        : Colors.grey.shade300;
    final Color backButtonBg = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFF5F5F5);

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: backButtonBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back_rounded, color: textColor, size: 20),
          ),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            // Appearance section
            _buildSectionTitle('Appearance', subtextColor),
            const SizedBox(height: 12),

            // Dark mode
            _buildSettingCard(
              icon: Icons.dark_mode_outlined,
              title: 'Theme',
              cardColor: cardColor,
              textColor: textColor,
              iconBgColor: iconBgColor,
              child: _buildThemeSelector(
                selectorBg,
                selectorBorder,
                subtextColor,
              ),
            ),

            const SizedBox(height: 12),

            // UI Scale
            _buildSettingCard(
              icon: Icons.format_size_rounded,
              title: 'UI Scale',
              cardColor: cardColor,
              textColor: textColor,
              iconBgColor: iconBgColor,
              child: _buildScaleSelector(
                selectorBg,
                selectorBorder,
                subtextColor,
              ),
            ),

            const SizedBox(height: 28),

            // Notifications section
            _buildSectionTitle('Notifications', subtextColor),
            const SizedBox(height: 12),

            _buildToggleSetting(
              icon: Icons.notifications_outlined,
              title: 'Order Updates',
              subtitle: 'Get notified about order status changes',
              value: _notifications,
              cardColor: cardColor,
              textColor: textColor,
              subtextColor: subtextColor,
              iconBgColor: iconBgColor,
              onChanged: (value) async {
                setState(() => _notifications = value);
                await PreferencesService.setNotificationsEnabled(value);
              },
            ),

            const SizedBox(height: 28),

            // Language section
            _buildSectionTitle('Language', subtextColor),
            const SizedBox(height: 12),

            _buildSettingCard(
              icon: Icons.language_rounded,
              title: 'App Language',
              cardColor: cardColor,
              textColor: textColor,
              iconBgColor: iconBgColor,
              child: _buildLanguageSelector(
                selectorBg,
                selectorBorder,
                subtextColor,
              ),
            ),

            const SizedBox(height: 28),

            // Storage section
            _buildSectionTitle('Storage', subtextColor),
            const SizedBox(height: 12),

            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Cache cleared'),
                    backgroundColor: Colors.teal.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.orange.shade900.withOpacity(0.3)
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.cleaning_services_rounded,
                        size: 20,
                        color: Colors.orange.shade600,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Clear Cache',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Free up storage space',
                            style: TextStyle(fontSize: 13, color: subtextColor),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: subtextColor,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required Color cardColor,
    required Color textColor,
    required Color iconBgColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: Colors.teal.shade700),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // Theme selector
  Widget _buildThemeSelector(
    Color selectorBg,
    Color selectorBorder,
    Color textColor,
  ) {
    return Row(
      children: [
        _buildThemeOption(
          'system',
          'System',
          Icons.phone_android_rounded,
          selectorBg,
          selectorBorder,
          textColor,
        ),
        const SizedBox(width: 8),
        _buildThemeOption(
          'light',
          'Light',
          Icons.light_mode_rounded,
          selectorBg,
          selectorBorder,
          textColor,
        ),
        const SizedBox(width: 8),
        _buildThemeOption(
          'dark',
          'Dark',
          Icons.dark_mode_rounded,
          selectorBg,
          selectorBorder,
          textColor,
        ),
      ],
    );
  }

  Widget _buildThemeOption(
    String value,
    String label,
    IconData icon,
    Color selectorBg,
    Color selectorBorder,
    Color textColor,
  ) {
    final isSelected = _darkMode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          setState(() => _darkMode = value);
          await PreferencesService.setDarkMode(value);
          _applyThemeChange();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.teal.shade600 : selectorBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.teal.shade600 : selectorBorder,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : textColor,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // UI Scale selector
  Widget _buildScaleSelector(
    Color selectorBg,
    Color selectorBorder,
    Color textColor,
  ) {
    final scales = [
      {'value': 'normal', 'label': 'Normal', 'fontSize': 16.0},
      {'value': 'medium', 'label': 'Medium', 'fontSize': 20.0},
      {'value': 'large', 'label': 'Large', 'fontSize': 24.0},
    ];

    return Row(
      children: scales.map((scale) {
        final isSelected = _uiScale == scale['value'];
        return Expanded(
          child: GestureDetector(
            onTap: () async {
              setState(() => _uiScale = scale['value'] as String);
              await PreferencesService.setUiScale(scale['value'] as String);
              _applyThemeChange();
            },
            child: Container(
              margin: EdgeInsets.only(right: scale['value'] != 'large' ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.teal.shade600 : selectorBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? Colors.teal.shade600 : selectorBorder,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Aa',
                    style: TextStyle(
                      fontSize: scale['fontSize'] as double,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    scale['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Language selector
  Widget _buildLanguageSelector(
    Color selectorBg,
    Color selectorBorder,
    Color textColor,
  ) {
    final languages = [
      {'value': 'en', 'label': 'English'},
      {'value': 'si', 'label': 'සිංහල'},
      {'value': 'ta', 'label': 'தமிழ்'},
    ];

    return Row(
      children: languages.map((lang) {
        final isSelected = _language == lang['value'];
        return Expanded(
          child: GestureDetector(
            onTap: () async {
              setState(() => _language = lang['value']!);
              await PreferencesService.setLanguage(lang['value']!);
              if (lang['value'] != 'en') {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Translation coming soon'),
                      backgroundColor: Colors.teal.shade600,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              }
            },
            child: Container(
              margin: EdgeInsets.only(right: lang['value'] != 'ta' ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.teal.shade600 : selectorBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? Colors.teal.shade600 : selectorBorder,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  lang['label']!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : textColor,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Toggle setting
  Widget _buildToggleSetting({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color cardColor,
    required Color textColor,
    required Color subtextColor,
    required Color iconBgColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: Colors.teal.shade700),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: subtextColor),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.teal.shade600,
          ),
        ],
      ),
    );
  }
}
