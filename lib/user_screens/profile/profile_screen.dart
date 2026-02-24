import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/auth_service.dart';
import '../../services/preferences_service.dart';
import '../../screens/role_selection_screen.dart';
import 'settings_screen.dart';
import 'edit_profile_screen.dart';
import '../address/saved_addresses_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '';
  String _phone = '';
  String _email = '';
  int _age = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    setState(() {
      _name = PreferencesService.getUserName() ?? 'User';
      _phone = PreferencesService.getUserPhone() ?? '';
      _email = PreferencesService.getUserEmail() ?? '';
      _age = PreferencesService.getUserAge() ?? 0;
    });
  }

  // ── Navigate to login, clearing everything behind us ──────────────────────
  void _goToLogin() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const RoleSelectionScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
      (route) => false, // remove every screen below — no going "back" to home
    );
  }

  void _logout() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color dialogBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color dialogText = isDark ? Colors.white : const Color(0xFF1A1A1A);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: dialogBg,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: Colors.red.shade500,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Log Out?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: dialogText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You will need to register again\nto use the app.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context); // close dialog first
                          // ✅ Actually sign out from Supabase — kills the token
                          await AuthService.signOut();
                          // AuthService.signOut() already calls
                          // PreferencesService.clearAll() internally
                          _goToLogin();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade500,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Log Out',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteAccount() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color dialogBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color dialogText = isDark ? Colors.white : const Color(0xFF1A1A1A);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: dialogBg,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.red.shade500,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Delete Account?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: dialogText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This action cannot be undone.\nAll your data will be permanently deleted.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context); // close dialog first
                          // ✅ Deletes profile row from DB + signs out
                          await AuthService.deleteAccount();
                          // AuthService.deleteAccount() calls signOut()
                          // which calls PreferencesService.clearAll()
                          _goToLogin();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade500,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final Color subtextColor = isDark
        ? Colors.grey.shade400
        : Colors.grey.shade500;
    final Color cardColor = isDark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFF8F9FA);
    final Color backBg = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFF5F5F5);

    String initial = _name.isNotEmpty ? _name[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: backBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back_rounded, color: textColor, size: 20),
          ),
        ),
        title: Text(
          'Profile',
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
          children: [
            const SizedBox(height: 16),
            // Profile avatar
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.teal.shade900 : Colors.teal.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Profile picture coming soon'),
                        backgroundColor: Colors.teal.shade600,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.teal.shade600,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF121212) : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _name,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _phone.isNotEmpty ? '+94 $_phone' : 'No phone added',
              style: TextStyle(fontSize: 15, color: subtextColor),
            ),
            const SizedBox(height: 32),
            _buildInfoSection(isDark, cardColor, subtextColor),
            const SizedBox(height: 24),
            _buildMenuItem(
              icon: Icons.edit_rounded,
              title: 'Edit Profile',
              subtitle: 'Update your personal details',
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              subtextColor: subtextColor,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
                _loadProfile();
              },
            ),
            _buildMenuItem(
              icon: Icons.location_on_outlined,
              title: 'Saved Addresses',
              subtitle: 'Manage delivery addresses',
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              subtextColor: subtextColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SavedAddressesScreen(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.settings_rounded,
              title: 'App Settings',
              subtitle: 'Theme, scale, notifications',
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              subtextColor: subtextColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.help_outline_rounded,
              title: 'Help & Support',
              subtitle: 'FAQ, contact us',
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              subtextColor: subtextColor,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Help section coming soon'),
                    backgroundColor: Colors.teal.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.info_outline_rounded,
              title: 'About ${AppConstants.appName}',
              subtitle: 'Version, terms, privacy',
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              subtextColor: subtextColor,
              onTap: () => _showAboutDialog(isDark),
            ),
            const SizedBox(height: 16),
            _buildMenuItem(
              icon: Icons.logout_rounded,
              title: 'Log Out',
              subtitle: 'Sign out of your account',
              isDestructive: true,
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              subtextColor: subtextColor,
              onTap: _logout,
            ),
            _buildMenuItem(
              icon: Icons.delete_outline_rounded,
              title: 'Delete Account',
              subtitle: 'Permanently remove your data',
              isDestructive: true,
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              subtextColor: subtextColor,
              onTap: _deleteAccount,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(bool isDark, Color cardColor, Color subtextColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
            label: 'Age',
            value: _age > 0 ? '$_age' : '-',
            isDark: isDark,
            subtextColor: subtextColor,
          ),
          Container(
            width: 1,
            height: 40,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          _buildInfoItem(
            label: 'Email',
            value: _email.isNotEmpty ? '✓' : '—',
            isDark: isDark,
            subtextColor: subtextColor,
          ),
          Container(
            width: 1,
            height: 40,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          _buildInfoItem(
            label: 'Orders',
            value: '0',
            isDark: isDark,
            subtextColor: subtextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required String label,
    required String value,
    required bool isDark,
    required Color subtextColor,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.teal.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 13, color: subtextColor)),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subtextColor,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDestructive
              ? (isDark
                    ? Colors.red.shade900.withOpacity(0.2)
                    : Colors.red.shade50.withOpacity(0.5))
              : cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isDestructive
                    ? (isDark ? Colors.red.shade900 : Colors.red.shade100)
                    : (isDark ? Colors.teal.shade900 : Colors.teal.shade50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDestructive
                    ? Colors.red.shade500
                    : Colors.teal.shade700,
              ),
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
                      color: isDestructive ? Colors.red.shade600 : textColor,
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
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(bool isDark) {
    final Color dialogBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: dialogBg,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.teal.shade700,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Medicine, delivered.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 20),
              Text(
                'Version 1.0.0 (Beta)',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 16),
              Text(
                '© 2025 ${AppConstants.appName}\nAll rights reserved.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
