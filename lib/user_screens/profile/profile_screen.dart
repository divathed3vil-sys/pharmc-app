import 'dart:ui';
import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../services/preferences_service.dart';
import '../../services/verification_service.dart';
import '../../services/app_config_service.dart';

import 'settings_screen.dart';
import 'edit_profile_screen.dart';
import '../address/saved_addresses_screen.dart';
import '../verification/verify_account_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  String _name = '';
  String _phone = '';
  String _email = '';
  int _age = 0;

  String _verificationStatus = 'unverified';
  bool _statusLoading = true;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadVerification();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _loadProfile() {
    setState(() {
      _name = PreferencesService.getUserName() ?? 'User';
      _phone = PreferencesService.getUserPhone() ?? '';
      _email = PreferencesService.getUserEmail() ?? '';
      _age = PreferencesService.getUserAge() ?? 0;
    });
  }

  Future<void> _loadVerification() async {
    setState(() => _statusLoading = true);
    try {
      final status = await VerificationService.getMyVerificationStatus();
      if (!mounted) return;
      setState(() {
        _verificationStatus = status;
        _statusLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _verificationStatus = 'unverified';
        _statusLoading = false;
      });
    }
  }

  bool get _isApproved => _verificationStatus == 'approved';

  Map<String, dynamic> _statusConfig(bool isDark) {
    switch (_verificationStatus) {
      case 'approved':
        return {
          'label': 'Verified',
          'color': Colors.green,
          'icon': Icons.verified_rounded,
          'desc': 'You can place real orders now.',
        };
      case 'pending':
        return {
          'label': 'Pending',
          'color': Colors.orange,
          'icon': Icons.hourglass_top_rounded,
          'desc': 'We are reviewing your verification request.',
        };
      case 'blocked':
        return {
          'label': 'Blocked',
          'color': Colors.red,
          'icon': Icons.block_rounded,
          'desc': 'Please contact support for help.',
        };
      case 'hold':
        return {
          'label': 'On hold',
          'color': Colors.amber,
          'icon': Icons.pause_circle_rounded,
          'desc': 'Your account is temporarily on hold.',
        };
      default:
        return {
          'label': 'Not verified',
          'color': Colors.teal,
          'icon': Icons.lock_outline_rounded,
          'desc': 'Verify your account to place orders.',
        };
    }
  }

  Route _smoothRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                ),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA);
    final text = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;

    final initial = _name.isNotEmpty ? _name[0].toUpperCase() : 'U';
    final status = _statusConfig(isDark);

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
          'Profile',
          style: TextStyle(
            color: text,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadVerification,
            icon: Icon(Icons.refresh_rounded, color: sub),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
            child: Column(
              children: [
                _glassCard(
                  isDark: isDark,
                  child: Column(
                    children: [
                      // Big avatar
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.teal.shade400,
                              Colors.teal.shade700,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.teal.withOpacity(
                                isDark ? 0.25 : 0.25,
                              ),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                              spreadRadius: -6,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _name,
                        style: TextStyle(
                          color: text,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _phone.isNotEmpty ? '+94 $_phone' : 'No phone',
                        style: TextStyle(
                          color: sub,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _email.isNotEmpty ? _email : 'No email',
                        style: TextStyle(color: sub, fontSize: 12),
                      ),
                      const SizedBox(height: 16),

                      // Status chip row
                      _statusPill(
                        isDark: isDark,
                        color: status['color'] as Color,
                        icon: status['icon'] as IconData,
                        label: status['label'] as String,
                        loading: _statusLoading,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        status['desc'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: sub, height: 1.4),
                      ),

                      // Verify CTA (top card, only if not approved)
                      if (!_isApproved) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              _smoothRoute(const VerifyAccountScreen()),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade600,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              'Verify account',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Stats glass row (Age/Email/Orders)
                _glassCard(
                  isDark: isDark,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _infoItem('Age', _age > 0 ? '$_age' : '-', sub),
                      _divider(isDark),
                      _infoItem('Email', _email.isNotEmpty ? '✓' : '—', sub),
                      _divider(isDark),
                      _infoItem('Orders', '0', sub),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                _menuTile(
                  isDark: isDark,
                  icon: Icons.edit_rounded,
                  title: 'Edit Profile',
                  subtitle: 'Update your personal details',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      _smoothRoute(const EditProfileScreen()),
                    );
                    _loadProfile();
                    _loadVerification();
                  },
                ),
                _menuTile(
                  isDark: isDark,
                  icon: Icons.location_on_outlined,
                  title: 'Saved Addresses',
                  subtitle: 'Manage delivery addresses',
                  onTap: () => Navigator.push(
                    context,
                    _smoothRoute(const SavedAddressesScreen()),
                  ),
                ),
                _menuTile(
                  isDark: isDark,
                  icon: Icons.settings_rounded,
                  title: 'Settings',
                  subtitle: 'Theme, language, security',
                  onTap: () => Navigator.push(
                    context,
                    _smoothRoute(const SettingsScreen()),
                  ),
                ),

                const SizedBox(height: 10),

                _menuTile(
                  isDark: isDark,
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  subtitle: 'Send issues, requests or suggestions',
                  onTap: _showSupportDialog,
                ),
                _menuTile(
                  isDark: isDark,
                  icon: Icons.info_outline_rounded,
                  title: 'About ${AppConstants.appName}',
                  subtitle: 'Credits and info',
                  onTap: () => _showAboutSheet(isDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Container(
      width: 1,
      height: 34,
      color: isDark
          ? Colors.white.withOpacity(0.08)
          : Colors.black.withOpacity(0.08),
    );
  }

  Widget _infoItem(String label, String value, Color sub) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.teal.shade400,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: sub)),
      ],
    );
  }

  Widget _statusPill({
    required bool isDark,
    required Color color,
    required IconData icon,
    required String label,
    required bool loading,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          else
            Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuTile({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final text = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;

    final iconBg = destructive
        ? Colors.red.withOpacity(isDark ? 0.18 : 0.10)
        : Colors.teal.withOpacity(isDark ? 0.18 : 0.10);

    final iconColor = destructive ? Colors.red.shade400 : Colors.teal.shade400;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _glassCard(
          isDark: isDark,
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (destructive ? Colors.red : Colors.teal).withOpacity(
                      isDark ? 0.22 : 0.16,
                    ),
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: destructive ? Colors.red.shade400 : text,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: sub, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: sub, size: 22),
            ],
          ),
        ),
      ),
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

  void _showSupportDialog() {
    final email = AppConfigService.getSupportEmail();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Support',
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
                  Icons.support_agent_rounded,
                  color: Colors.teal.shade400,
                  size: 40,
                ),
                const SizedBox(height: 10),
                Text(
                  'Help & Support',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Submit any problems, requests or suggestions to:',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, height: 1.4),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.teal.withOpacity(0.22)),
                  ),
                  child: Text(
                    email,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.teal.shade400,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade600,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Got it',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
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
  }

  void _showAboutSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (_) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.white.withOpacity(0.92),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.05),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      AppConstants.appName,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Medicine, delivered.',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 16),

                    // Credits cards
                    Row(
                      children: [
                        Expanded(
                          child: _creditCard(
                            isDark: isDark,
                            title: 'Project by',
                            name: AppConfigService.getProjectByName(),
                            icon: Icons.lightbulb_rounded,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _creditCard(
                            isDark: isDark,
                            title: 'Developed by',
                            name: AppConfigService.getDeveloperName(),
                            icon: Icons.code_rounded,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade600,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _creditCard({
    required bool isDark,
    required String title,
    required String name,
    required IconData icon,
    required MaterialColor color,
  }) {
    final text = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color.shade400),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: TextStyle(
              color: text,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Profile coming soon',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
        ],
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
