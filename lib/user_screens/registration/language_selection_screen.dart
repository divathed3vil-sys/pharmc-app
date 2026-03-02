import 'dart:ui';
import 'package:flutter/material.dart';

import '../../constants.dart';
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
  String? _selectedCode;

  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
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
          content: const Text('Sinhala / Tamil coming soon'),
          backgroundColor: Colors.teal.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() {
      _loading = true;
      _selectedCode = code;
    });

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

    final bg = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: bg,
        body: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: SafeArea(
              child: Stack(
                children: [
                  // ── Background blobs ──
                  Positioned(
                    top: -130,
                    right: -120,
                    child: _blurBlob(
                      color: Colors.teal.withOpacity(isDark ? 0.20 : 0.14),
                      size: 300,
                    ),
                  ),
                  Positioned(
                    bottom: -150,
                    left: -130,
                    child: _blurBlob(
                      color: Colors.indigo.withOpacity(isDark ? 0.16 : 0.10),
                      size: 320,
                    ),
                  ),

                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Brand ──
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            AppConstants.appName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.teal.shade400,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Header card ──
                        _glassCard(
                          isDark: isDark,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Globe icon ──
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.teal.withOpacity(
                                    isDark ? 0.15 : 0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.teal.withOpacity(0.15),
                                  ),
                                ),
                                child: Icon(
                                  Icons.translate_rounded,
                                  color: Colors.teal.shade400,
                                  size: 24,
                                ),
                              ),

                              const SizedBox(height: 16),

                              Text(
                                'Choose your language',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: textColor,
                                  letterSpacing: -0.4,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                'You can change this anytime in Settings.\nSinhala and Tamil support is coming soon.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: sub,
                                  height: 1.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ── English (Available) ──
                        _languageTile(
                          isDark: isDark,
                          textColor: textColor,
                          sub: sub,
                          title: 'English',
                          nativeLabel: 'English',
                          code: 'en',
                          available: true,
                          accentColor: Colors.teal,
                          icon: Icons.check_circle_rounded,
                        ),

                        const SizedBox(height: 10),

                        // ── Sinhala (Coming soon) ──
                        _languageTile(
                          isDark: isDark,
                          textColor: textColor,
                          sub: sub,
                          title: 'Sinhala',
                          nativeLabel: 'සිංහල',
                          code: 'si',
                          available: false,
                          accentColor: Colors.orange,
                          icon: Icons.schedule_rounded,
                        ),

                        const SizedBox(height: 10),

                        // ── Tamil (Coming soon) ──
                        _languageTile(
                          isDark: isDark,
                          textColor: textColor,
                          sub: sub,
                          title: 'Tamil',
                          nativeLabel: 'தமிழ்',
                          code: 'ta',
                          available: false,
                          accentColor: Colors.orange,
                          icon: Icons.schedule_rounded,
                        ),

                        const SizedBox(height: 28),

                        // ── Footer note ──
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'By continuing, you agree to a better pharmacy experience.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: sub.withOpacity(0.8),
                                fontSize: 12,
                                height: 1.5,
                                fontWeight: FontWeight.w600,
                              ),
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

  // ════════════════════════════════════════════════
  // LANGUAGE TILE
  // ════════════════════════════════════════════════

  Widget _languageTile({
    required bool isDark,
    required Color textColor,
    required Color sub,
    required String title,
    required String nativeLabel,
    required String code,
    required bool available,
    required MaterialColor accentColor,
    required IconData icon,
  }) {
    final isSelected = _selectedCode == code && _loading;
    final effectiveOpacity = available ? 1.0 : 0.55;

    final tileBg = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.white.withOpacity(0.88);
    final tileBorder = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.05);

    // Highlight border when available
    final activeBorder = available ? accentColor.withOpacity(0.30) : tileBorder;

    return Opacity(
      opacity: effectiveOpacity,
      child: GestureDetector(
        onTap: _loading ? null : () => _select(code),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: tileBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: activeBorder, width: 1.5),
            boxShadow: available
                ? [
                    BoxShadow(
                      color: accentColor.withOpacity(isDark ? 0.08 : 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                      spreadRadius: -4,
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              // ── Language icon container ──
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(isDark ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accentColor.withOpacity(0.12)),
                ),
                child: Center(
                  child: Text(
                    nativeLabel.substring(0, 1),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: accentColor.shade600,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // ── Text ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nativeLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: sub,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Status badge ──
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(isDark ? 0.14 : 0.10),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: accentColor.withOpacity(0.18)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 13, color: accentColor.shade500),
                    const SizedBox(width: 4),
                    Text(
                      available ? 'Available' : 'Soon',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: accentColor.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              if (available) ...[
                const SizedBox(width: 8),
                if (isSelected)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accentColor.shade500,
                    ),
                  )
                else
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: sub),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════
  // SHARED WIDGETS
  // ════════════════════════════════════════════════

  Widget _glassCard({required bool isDark, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
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
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(width: size, height: size, color: color),
      ),
    );
  }
}
