import 'dart:ui';
import 'package:flutter/material.dart';

import '../../services/preferences_service.dart';
import '../main_navigation.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = false;

  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _select(String code) async {
    if (_loading) return;

    if (code != 'en') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sinhala/Tamil coming soon'),
          backgroundColor: Colors.teal.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    await PreferencesService.setLanguage(code);

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      _smoothRoute(const MainNavigation()),
      (route) => false,
    );
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
      transitionDuration: const Duration(milliseconds: 360),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA);
    final text = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;

    return PopScope(
      canPop: false, // Force language selection
      child: Scaffold(
        backgroundColor: bg,
        body: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    top: -140,
                    right: -140,
                    child: _blurBlob(
                      color: Colors.teal.withOpacity(isDark ? 0.22 : 0.14),
                      size: 300,
                    ),
                  ),
                  Positioned(
                    bottom: -160,
                    left: -140,
                    child: _blurBlob(
                      color: Colors.indigo.withOpacity(isDark ? 0.18 : 0.12),
                      size: 320,
                    ),
                  ),
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _glassCard(
                          isDark: isDark,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Choose language',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: text,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'You can change this later in Settings.\nSinhala and Tamil will be added soon.',
                                style: TextStyle(
                                  color: sub,
                                  height: 1.4,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        _langCard(
                          isDark: isDark,
                          title: 'English',
                          subtitle: 'Recommended',
                          badge: 'Available',
                          badgeColor: Colors.green,
                          icon: Icons.language_rounded,
                          gradient: [
                            Colors.teal.shade500,
                            Colors.teal.shade700,
                          ],
                          enabled: true,
                          onTap: () => _select('en'),
                          loading: _loading,
                        ),

                        const SizedBox(height: 12),

                        _langCard(
                          isDark: isDark,
                          title: 'සිංහල',
                          subtitle: 'Coming soon',
                          badge: 'Soon',
                          badgeColor: Colors.orange,
                          icon: Icons.lock_rounded,
                          gradient: [
                            Colors.grey.shade700,
                            Colors.grey.shade800,
                          ],
                          enabled: false,
                          onTap: () => _select('si'),
                          loading: _loading,
                        ),

                        const SizedBox(height: 12),

                        _langCard(
                          isDark: isDark,
                          title: 'தமிழ்',
                          subtitle: 'Coming soon',
                          badge: 'Soon',
                          badgeColor: Colors.orange,
                          icon: Icons.lock_rounded,
                          gradient: [
                            Colors.grey.shade700,
                            Colors.grey.shade800,
                          ],
                          enabled: false,
                          onTap: () => _select('ta'),
                          loading: _loading,
                        ),

                        const SizedBox(height: 18),

                        Center(
                          child: Text(
                            'By continuing, you agree to a better pharmacy experience.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: sub.withOpacity(0.9),
                              fontSize: 12,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _langCard({
    required bool isDark,
    required String title,
    required String subtitle,
    required String badge,
    required MaterialColor badgeColor,
    required IconData icon,
    required List<Color> gradient,
    required bool enabled,
    required VoidCallback onTap,
    required bool loading,
  }) {
    final opacity = enabled ? 1.0 : 0.55;

    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: loading ? null : onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.first.withOpacity(isDark ? 0.30 : 0.25),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                      spreadRadius: -8,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.10),
                        ),
                      ),
                      child: Icon(icon, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: badgeColor.withOpacity(0.25)),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (enabled)
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white.withOpacity(0.9),
                      ),
                  ],
                ),
              ),

              if (loading && enabled)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.12),
                    child: const Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassCard({required bool isDark, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
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

  Widget _blurBlob({required Color color, required double size}) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(width: size, height: size, color: color),
      ),
    );
  }
}
