import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF1A1A1A),
              size: 20,
            ),
          ),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
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
            _buildSectionTitle('Appearance'),
            const SizedBox(height: 12),

            // Dark mode
            _buildSettingCard(
              icon: Icons.dark_mode_outlined,
              title: 'Theme',
              child: _buildThemeSelector(),
            ),

            const SizedBox(height: 12),

            // UI Scale
            _buildSettingCard(
              icon: Icons.format_size_rounded,
              title: 'UI Scale',
              child: _buildScaleSelector(),
            ),

            const SizedBox(height: 28),

            // Notifications section
            _buildSectionTitle('Notifications'),
            const SizedBox(height: 12),

            _buildToggleSetting(
              icon: Icons.notifications_outlined,
              title: 'Order Updates',
              subtitle: 'Get notified about order status changes',
              value: _notifications,
              onChanged: (value) async {
                setState(() => _notifications = value);
                await PreferencesService.setNotificationsEnabled(value);
              },
            ),

            const SizedBox(height: 28),

            // Language section
            _buildSectionTitle('Language'),
            const SizedBox(height: 12),

            _buildSettingCard(
              icon: Icons.language_rounded,
              title: 'App Language',
              child: _buildLanguageSelector(),
            ),

            const SizedBox(height: 28),

            // Storage section
            _buildSectionTitle('Storage'),
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
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.cleaning_services_rounded,
                        size: 20,
                        color: Colors.orange.shade600,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Clear Cache',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Free up storage space',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey.shade400,
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade500,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
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
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: Colors.teal.shade700),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
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

  // Theme selector (System / Light / Dark)
  Widget _buildThemeSelector() {
    return Row(
      children: [
        _buildThemeOption('system', 'System', Icons.phone_android_rounded),
        const SizedBox(width: 8),
        _buildThemeOption('light', 'Light', Icons.light_mode_rounded),
        const SizedBox(width: 8),
        _buildThemeOption('dark', 'Dark', Icons.dark_mode_rounded),
      ],
    );
  }

  Widget _buildThemeOption(String value, String label, IconData icon) {
    final isSelected = _darkMode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          setState(() => _darkMode = value);
          await PreferencesService.setDarkMode(value);
          // Future: Actually apply theme via ThemeService
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.teal.shade600 : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.teal.shade600 : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // UI Scale selector
  Widget _buildScaleSelector() {
    final scales = [
      {'value': 'normal', 'label': 'Normal', 'size': 'Aa'},
      {'value': 'medium', 'label': 'Medium', 'size': 'Aa'},
      {'value': 'large', 'label': 'Large', 'size': 'Aa'},
    ];

    return Row(
      children: scales.map((scale) {
        final isSelected = _uiScale == scale['value'];
        final fontSize = scale['value'] == 'normal'
            ? 16.0
            : scale['value'] == 'medium'
            ? 20.0
            : 24.0;

        return Expanded(
          child: GestureDetector(
            onTap: () async {
              setState(() => _uiScale = scale['value']!);
              await PreferencesService.setUiScale(scale['value']!);
              // Future: Actually apply scale via ThemeService
            },
            child: Container(
              margin: EdgeInsets.only(right: scale['value'] != 'large' ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.teal.shade600 : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? Colors.teal.shade600
                      : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    scale['size']!,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    scale['label']!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
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
  Widget _buildLanguageSelector() {
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
            },
            child: Container(
              margin: EdgeInsets.only(right: lang['value'] != 'ta' ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.teal.shade600 : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? Colors.teal.shade600
                      : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  lang['label']!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
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
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
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
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.teal.shade600,
          ),
        ],
      ),
    );
  }
}
