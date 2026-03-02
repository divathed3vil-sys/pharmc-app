import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants.dart';
import '../../services/auth_service.dart';
import '../../services/preferences_service.dart';
import 'login_screen.dart';

class BlockedAccountScreen extends StatefulWidget {
  final String? blockedReason;

  const BlockedAccountScreen({super.key, this.blockedReason});

  @override
  State<BlockedAccountScreen> createState() => _BlockedAccountScreenState();
}

class _BlockedAccountScreenState extends State<BlockedAccountScreen>
    with SingleTickerProviderStateMixin {
  bool _signingOut = false;

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

  String _buildWhatsAppUrl() {
    final phone = PreferencesService.getUserPhone();
    final number = AppConstants.supportWhatsAppNumberE164Digits;

    String message;
    if (phone != null && phone.isNotEmpty) {
      message =
          'Hello ${AppConstants.appName} Support, my account is blocked. '
          'Phone: +94$phone. Please assist.';
    } else {
      message =
          'Hello ${AppConstants.appName} Support, my account is blocked. '
          'Please assist.';
    }

    final encoded = Uri.encodeComponent(message);
    return 'https://wa.me/$number?text=$encoded';
  }

  Future<void> _openWhatsApp() async {
    final url = _buildWhatsAppUrl();
    final uri = Uri.parse(url);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open WhatsApp'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('WhatsApp is not installed'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);

    await AuthService.signOutLocalOnly();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;

    final hasReason =
        widget.blockedReason != null && widget.blockedReason!.trim().isNotEmpty;

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
                    top: -100,
                    left: -120,
                    child: _blurBlob(
                      color: Colors.red.withOpacity(isDark ? 0.18 : 0.12),
                      size: 280,
                    ),
                  ),
                  Positioned(
                    bottom: -140,
                    right: -100,
                    child: _blurBlob(
                      color: Colors.orange.withOpacity(isDark ? 0.14 : 0.10),
                      size: 260,
                    ),
                  ),

                  Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── Shield icon ──
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(
                                isDark ? 0.15 : 0.10,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.red.withOpacity(0.20),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              Icons.shield_rounded,
                              size: 40,
                              color: Colors.red.shade400,
                            ),
                          ),

                          const SizedBox(height: 28),

                          // ── Title ──
                          Text(
                            'Account Blocked',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                              letterSpacing: -0.5,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ── Subtitle ──
                          Text(
                            'Your account has been suspended.\nPlease contact support for assistance.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: sub,
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          // ── Blocked reason card ──
                          if (hasReason) ...[
                            const SizedBox(height: 24),
                            _glassCard(
                              isDark: isDark,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(
                                        isDark ? 0.15 : 0.10,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.info_outline_rounded,
                                      size: 18,
                                      color: Colors.red.shade400,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Reason',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: sub,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          widget.blockedReason!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: textColor,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 32),

                          // ── WhatsApp support button ──
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton.icon(
                              onPressed: _openWhatsApp,
                              icon: const Icon(Icons.chat_rounded, size: 20),
                              label: const Text(
                                'Contact Support on WhatsApp',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // ── Sign out button ──
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: _signingOut ? null : _signOut,
                              icon: _signingOut
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: sub,
                                      ),
                                    )
                                  : Icon(
                                      Icons.logout_rounded,
                                      size: 18,
                                      color: sub,
                                    ),
                              label: Text(
                                'Sign Out',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: sub,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.12)
                                      : Colors.black.withOpacity(0.10),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
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
  // SHARED WIDGETS
  // ════════════════════════════════════════════════

  Widget _blurBlob({required Color color, required double size}) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(width: size, height: size, color: color),
      ),
    );
  }

  Widget _glassCard({required bool isDark, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.white.withOpacity(0.90),
            borderRadius: BorderRadius.circular(20),
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
