import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../main.dart';
import '../../services/preferences_service.dart';
import '../../services/auth_service.dart';
import '../registration/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  String _darkMode = 'system';
  String _uiScale = 'normal';
  bool _notifications = true;
  String _language = 'en';

  // Share account state
  String? _shareCode;
  bool _shareLoading = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _darkMode = PreferencesService.getDarkMode();
    _uiScale = PreferencesService.getUiScale();
    _notifications = PreferencesService.getNotificationsEnabled();
    _language = PreferencesService.getLanguage();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    // Load existing share code on init
    _loadShareCode();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _applyThemeChange() {
    MyApp.refresh(context);
  }

  // ============ SHARE CODE METHODS ============

  Future<void> _loadShareCode() async {
    final code = await AuthService.getShareCode();
    if (!mounted) return;
    setState(() => _shareCode = code);
  }

  Future<void> _generateShareCode() async {
    setState(() => _shareLoading = true);

    final result = await AuthService.generateShareCode();

    if (!mounted) return;
    setState(() => _shareLoading = false);

    if (result.success && result.shareCode != null) {
      setState(() => _shareCode = result.shareCode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Share code generated!'),
          backgroundColor: Colors.teal.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _revokeShareCode() async {
    setState(() => _shareLoading = true);

    final result = await AuthService.clearShareCode();

    if (!mounted) return;
    setState(() => _shareLoading = false);

    if (result.success) {
      setState(() => _shareCode = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Share code revoked.'),
          backgroundColor: Colors.teal.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _copyShareCode() {
    if (_shareCode == null || _shareCode!.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _shareCode!));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Share code copied to clipboard!'),
        backgroundColor: Colors.teal.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ============ NAVIGATION ============

  void _goToLogin() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
      (route) => false,
    );
  }

  Future<void> _logout() async {
    await AuthService.signOut();
    _goToLogin();
  }

  Future<void> _showLogoutConfirm() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final ok = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Logout',
      barrierColor: Colors.black.withOpacity(isDark ? 0.6 : 0.4),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => Center(
        child: Material(
          color: Colors.transparent,
          child: _glassDialog(
            isDark: isDark,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: Colors.red.shade400,
                  size: 40,
                ),
                const SizedBox(height: 10),
                Text(
                  'Log out?',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'You will need to login again to use the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, height: 1.4),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade500,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Log out',
                            style: TextStyle(fontWeight: FontWeight.w900),
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
      ),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      ),
    );

    if (ok == true) {
      await _logout();
    }
  }

  Future<void> _showDeleteConfirm() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final ok = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Delete account',
      barrierColor: Colors.black.withOpacity(isDark ? 0.65 : 0.45),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => Center(
        child: Material(
          color: Colors.transparent,
          child: _glassDialog(
            isDark: isDark,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.red.shade400,
                  size: 44,
                ),
                const SizedBox(height: 12),
                Text(
                  'Delete account?',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'This action cannot be undone.\nAll your data, devices, and orders will be permanently removed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, height: 1.4),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade500,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Delete forever',
                            style: TextStyle(fontWeight: FontWeight.w900),
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
      ),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      ),
    );

    if (ok == true) {
      final result = await AuthService.deleteAccount();
      if (result.success) {
        _goToLogin();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA);
    final text = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: text, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(color: text, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Appearance', sub),
                const SizedBox(height: 10),
                _glassCard(
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _rowHeader(
                        isDark: isDark,
                        icon: Icons.color_lens_rounded,
                        title: 'Theme',
                        subtitle: 'Light / Dark / System',
                      ),
                      const SizedBox(height: 14),
                      _segmentedTheme(isDark, text, sub),
                      const SizedBox(height: 16),
                      _rowHeader(
                        isDark: isDark,
                        icon: Icons.format_size_rounded,
                        title: 'UI Scale',
                        subtitle: 'Adjust text size',
                      ),
                      const SizedBox(height: 14),
                      _segmentedScale(isDark, text, sub),
                    ],
                  ),
                ),

                const SizedBox(height: 18),
                _sectionTitle('Notifications', sub),
                const SizedBox(height: 10),
                _glassCard(
                  isDark: isDark,
                  child: Row(
                    children: [
                      _iconBox(
                        isDark,
                        Icons.notifications_rounded,
                        Colors.teal,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order updates',
                              style: TextStyle(
                                color: text,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Get order status changes',
                              style: TextStyle(color: sub, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _notifications,
                        onChanged: (v) async {
                          setState(() => _notifications = v);
                          await PreferencesService.setNotificationsEnabled(v);
                        },
                        activeThumbColor: Colors.teal.shade600,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),
                _sectionTitle('Language', sub),
                const SizedBox(height: 10),
                _glassCard(
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _rowHeader(
                        isDark: isDark,
                        icon: Icons.language_rounded,
                        title: 'App language',
                        subtitle: 'Sinhala/Tamil coming soon',
                      ),
                      const SizedBox(height: 14),
                      _segmentedLanguage(isDark, text, sub),
                    ],
                  ),
                ),

                const SizedBox(height: 18),
                _sectionTitle('Share Account', sub),
                const SizedBox(height: 10),
                _shareAccountCard(isDark, text, sub),

                const SizedBox(height: 18),
                _sectionTitle('Storage', sub),
                const SizedBox(height: 10),
                _menuTile(
                  isDark: isDark,
                  icon: Icons.cleaning_services_rounded,
                  title: 'Clear cache',
                  subtitle: 'Free up storage space',
                  color: Colors.orange,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Cache cleared'),
                        backgroundColor: Colors.teal.shade600,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 18),
                _sectionTitle('Security', sub),
                const SizedBox(height: 10),
                _menuTile(
                  isDark: isDark,
                  icon: Icons.logout_rounded,
                  title: 'Log out',
                  subtitle: 'Sign out of your account',
                  color: Colors.red,
                  onTap: _showLogoutConfirm,
                ),
                _menuTile(
                  isDark: isDark,
                  icon: Icons.delete_forever_rounded,
                  title: 'Delete account',
                  subtitle: 'Permanent removal of all data',
                  color: Colors.red,
                  onTap: _showDeleteConfirm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============ SHARE ACCOUNT CARD ============

  Widget _shareAccountCard(bool isDark, Color text, Color sub) {
    return _glassCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(isDark, Icons.share_rounded, Colors.teal),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share Account',
                      style: TextStyle(
                        color: text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Let another device join your account',
                      style: TextStyle(color: sub, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Info text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(isDark ? 0.10 : 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.teal.withOpacity(0.18)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.teal.shade400,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Generate a 6-digit code and share it with another device. '
                    'Maximum 4 devices per account. Code is one-time use.',
                    style: TextStyle(
                      color: isDark
                          ? Colors.teal.shade200
                          : Colors.teal.shade800,
                      fontSize: 11,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Share code display or generate button
          if (_shareCode != null && _shareCode!.isNotEmpty) ...[
            // Code display card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.teal.shade400.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Your share code',
                    style: TextStyle(
                      color: sub,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _shareCode!.split('').map((digit) {
                      return Container(
                        width: 40,
                        height: 48,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(isDark ? 0.15 : 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.teal.shade400.withOpacity(0.3),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            digit,
                            style: TextStyle(
                              color: Colors.teal.shade400,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: OutlinedButton.icon(
                            onPressed: _shareLoading ? null : _copyShareCode,
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: const Text(
                              'Copy',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.teal.shade400,
                              side: BorderSide(
                                color: Colors.teal.shade400.withOpacity(0.4),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: OutlinedButton.icon(
                            onPressed: _shareLoading ? null : _revokeShareCode,
                            icon: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Colors.red.shade400,
                            ),
                            label: Text(
                              'Revoke',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Colors.red.shade400,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.red.shade400.withOpacity(0.4),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Regenerate
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: _shareLoading ? null : _generateShareCode,
                icon: _shareLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.teal.shade400,
                        ),
                      )
                    : Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: Colors.teal.shade400,
                      ),
                label: Text(
                  'Generate new code',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.teal.shade400,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Colors.teal.shade400.withOpacity(0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ] else ...[
            // No code yet — show generate button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _shareLoading ? null : _generateShareCode,
                icon: _shareLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.qr_code_rounded, size: 20),
                label: const Text(
                  'Generate share code',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============ EXISTING WIDGETS (unchanged) ============

  Widget _sectionTitle(String t, Color sub) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        t.toUpperCase(),
        style: TextStyle(
          color: sub,
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _rowHeader({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final text = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;

    return Row(
      children: [
        _iconBox(isDark, icon, Colors.teal),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: text, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: sub, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _segmentedTheme(bool isDark, Color text, Color sub) {
    return Row(
      children: [
        _segOption(
          isDark: isDark,
          value: 'system',
          current: _darkMode,
          label: 'System',
          icon: Icons.phone_android_rounded,
          enabled: true,
          onTap: () async {
            setState(() => _darkMode = 'system');
            await PreferencesService.setDarkMode('system');
            _applyThemeChange();
          },
        ),
        const SizedBox(width: 8),
        _segOption(
          isDark: isDark,
          value: 'light',
          current: _darkMode,
          label: 'Light',
          icon: Icons.light_mode_rounded,
          enabled: true,
          onTap: () async {
            setState(() => _darkMode = 'light');
            await PreferencesService.setDarkMode('light');
            _applyThemeChange();
          },
        ),
        const SizedBox(width: 8),
        _segOption(
          isDark: isDark,
          value: 'dark',
          current: _darkMode,
          label: 'Dark',
          icon: Icons.dark_mode_rounded,
          enabled: true,
          onTap: () async {
            setState(() => _darkMode = 'dark');
            await PreferencesService.setDarkMode('dark');
            _applyThemeChange();
          },
        ),
      ],
    );
  }

  Widget _segmentedScale(bool isDark, Color text, Color sub) {
    return Row(
      children: [
        _segOption(
          isDark: isDark,
          value: 'normal',
          current: _uiScale,
          label: 'Normal',
          icon: Icons.text_fields_rounded,
          enabled: true,
          onTap: () async {
            setState(() => _uiScale = 'normal');
            await PreferencesService.setUiScale('normal');
            _applyThemeChange();
          },
        ),
        const SizedBox(width: 8),
        _segOption(
          isDark: isDark,
          value: 'medium',
          current: _uiScale,
          label: 'Medium',
          icon: Icons.format_size_rounded,
          enabled: true,
          onTap: () async {
            setState(() => _uiScale = 'medium');
            await PreferencesService.setUiScale('medium');
            _applyThemeChange();
          },
        ),
        const SizedBox(width: 8),
        _segOption(
          isDark: isDark,
          value: 'large',
          current: _uiScale,
          label: 'Large',
          icon: Icons.text_increase_rounded,
          enabled: true,
          onTap: () async {
            setState(() => _uiScale = 'large');
            await PreferencesService.setUiScale('large');
            _applyThemeChange();
          },
        ),
      ],
    );
  }

  Widget _segmentedLanguage(bool isDark, Color text, Color sub) {
    return Row(
      children: [
        _segOption(
          isDark: isDark,
          value: 'en',
          current: _language,
          label: 'English',
          icon: Icons.language_rounded,
          enabled: true,
          onTap: () async {
            setState(() => _language = 'en');
            await PreferencesService.setLanguage('en');
          },
        ),
        const SizedBox(width: 8),
        _segOption(
          isDark: isDark,
          value: 'si',
          current: _language,
          label: 'සිංහල',
          icon: Icons.lock_rounded,
          enabled: false,
          onTap: () {},
        ),
        const SizedBox(width: 8),
        _segOption(
          isDark: isDark,
          value: 'ta',
          current: _language,
          label: 'தமிழ்',
          icon: Icons.lock_rounded,
          enabled: false,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _segOption({
    required bool isDark,
    required String value,
    required String current,
    required String label,
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final selected = current == value;

    final bg = selected
        ? Colors.teal.shade600
        : (isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.03));

    final border = selected
        ? Colors.teal.shade600
        : (isDark
              ? Colors.white.withOpacity(0.10)
              : Colors.black.withOpacity(0.06));

    final fg = selected
        ? Colors.white
        : (isDark ? Colors.white : const Color(0xFF1A1A1A));

    return Expanded(
      child: GestureDetector(
        onTap: enabled
            ? onTap
            : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Coming soon'),
                    backgroundColor: Colors.teal.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: enabled ? 1.0 : 0.45,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border, width: 1.3),
            ),
            child: Column(
              children: [
                Icon(icon, size: 18, color: fg),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuTile({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required MaterialColor color,
    required VoidCallback onTap,
  }) {
    final text = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: _glassCard(
          isDark: isDark,
          child: Row(
            children: [
              _iconBox(isDark, icon, color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: sub, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: sub),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBox(bool isDark, IconData icon, MaterialColor color) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Icon(icon, color: color.shade400, size: 22),
    );
  }

  Widget _glassCard({required bool isDark, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _glassDialog({required bool isDark, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.88,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
