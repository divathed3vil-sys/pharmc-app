import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants.dart';
import '../user_screens/registration/login_screen.dart';
import '../user_screens/registration/blocked_account_screen.dart';
import '../services/preferences_service.dart';
import '../services/auth_service.dart';
import '../user_screens/main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ════════════════════════════════════════════════
  // ANIMATION CONTROLLERS
  // ════════════════════════════════════════════════

  late final AnimationController _blobController;
  late final Animation<Offset> _blob1Drift;
  late final Animation<Offset> _blob2Drift;
  late final Animation<Offset> _blob3Drift;

  late final AnimationController _nameController;
  late final Animation<double> _nameFade;
  late final Animation<double> _nameSpring;

  late final AnimationController _glowController;
  late final Animation<double> _glowAnim;

  late final AnimationController _subtitleController;
  late final Animation<double> _subtitleFade;
  late final Animation<Offset> _subtitleSlide;

  late final AnimationController _exitController;
  late final Animation<double> _exitFade;
  late final Animation<double> _exitScale;

  @override
  void initState() {
    super.initState();

    // ── Background blobs ──
    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    _blob1Drift =
        Tween<Offset>(
          begin: const Offset(-0.03, -0.02),
          end: const Offset(0.03, 0.02),
        ).animate(
          CurvedAnimation(parent: _blobController, curve: Curves.easeInOutSine),
        );

    _blob2Drift =
        Tween<Offset>(
          begin: const Offset(0.02, 0.03),
          end: const Offset(-0.02, -0.01),
        ).animate(
          CurvedAnimation(parent: _blobController, curve: Curves.easeInOutSine),
        );

    _blob3Drift =
        Tween<Offset>(
          begin: const Offset(0.01, -0.03),
          end: const Offset(-0.03, 0.02),
        ).animate(
          CurvedAnimation(parent: _blobController, curve: Curves.easeInOutSine),
        );

    _blobController.repeat(reverse: true);

    // ── App name ──
    _nameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _nameFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _nameController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _nameSpring = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _nameController, curve: Curves.elasticOut),
    );

    // ── Glow pulse ──
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _glowAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 0.45,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.45,
          end: 0.15,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_glowController);

    // ── Subtitle ──
    _subtitleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _subtitleController, curve: Curves.easeOut),
    );

    _subtitleSlide =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _subtitleController,
            curve: Curves.easeOutCubic,
          ),
        );

    // ── Exit ──
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
    );

    _exitScale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
    );

    _startSequence();
  }

  // ════════════════════════════════════════════════
  // SPLASH SEQUENCE
  // ════════════════════════════════════════════════

  void _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    _nameController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _glowController.repeat(reverse: true);

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _subtitleController.forward();

    await Future.delayed(const Duration(milliseconds: 2100));
    if (!mounted) return;

    _exitController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // ── Session validation ──
    Widget destination;
    try {
      final sessionResult = await AuthService.validateSession();

      if (sessionResult.valid) {
        destination = const MainNavigation();
      } else if (sessionResult.reason == 'blocked') {
        // Route directly to BlockedAccountScreen — no SnackBar
        destination = BlockedAccountScreen(
          blockedReason: sessionResult.blockedReason,
        );
      } else if (sessionResult.reason == 'device_not_found' ||
          sessionResult.reason == 'user_deleted' ||
          sessionResult.reason == 'no_device') {
        destination = const LoginScreen();
      } else if (sessionResult.reason == 'error') {
        if (AuthService.isLoggedIn()) {
          destination = const MainNavigation();
        } else {
          destination = const LoginScreen();
        }
      } else {
        destination = const LoginScreen();
      }
    } catch (_) {
      if (AuthService.isLoggedIn()) {
        destination = const MainNavigation();
      } else {
        destination = const LoginScreen();
      }
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _blobController.dispose();
    _nameController.dispose();
    _glowController.dispose();
    _subtitleController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: bg,
      body: AnimatedBuilder(
        animation: Listenable.merge([_exitController, _blobController]),
        builder: (context, child) {
          return FadeTransition(
            opacity: _exitFade,
            child: ScaleTransition(
              scale: _exitScale,
              child: Stack(
                children: [
                  _buildAnimatedBlob(
                    screenSize: screenSize,
                    isDark: isDark,
                    drift: _blob1Drift,
                    baseLeft: -80,
                    baseTop: screenSize.height * 0.15,
                    size: 280,
                    color: isDark
                        ? Colors.teal.shade900.withOpacity(0.35)
                        : Colors.teal.shade200.withOpacity(0.30),
                    blurSigma: 60,
                  ),
                  _buildAnimatedBlob(
                    screenSize: screenSize,
                    isDark: isDark,
                    drift: _blob2Drift,
                    baseLeft: screenSize.width - 100,
                    baseTop: screenSize.height * 0.55,
                    size: 220,
                    color: isDark
                        ? Colors.cyan.shade900.withOpacity(0.25)
                        : Colors.cyan.shade100.withOpacity(0.35),
                    blurSigma: 50,
                  ),
                  _buildAnimatedBlob(
                    screenSize: screenSize,
                    isDark: isDark,
                    drift: _blob3Drift,
                    baseLeft: screenSize.width * 0.3,
                    baseTop: -60,
                    size: 200,
                    color: isDark
                        ? Colors.teal.shade800.withOpacity(0.20)
                        : Colors.teal.shade100.withOpacity(0.25),
                    blurSigma: 55,
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildGlowLayer(isDark),
                        const SizedBox(height: 14),
                        SlideTransition(
                          position: _subtitleSlide,
                          child: FadeTransition(
                            opacity: _subtitleFade,
                            child: Text(
                              'Project by Harish & Diva.',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade400,
                                letterSpacing: 0.8,
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
          );
        },
      ),
    );
  }

  Widget _buildAnimatedBlob({
    required Size screenSize,
    required bool isDark,
    required Animation<Offset> drift,
    required double baseLeft,
    required double baseTop,
    required double size,
    required Color color,
    required double blurSigma,
  }) {
    return AnimatedBuilder(
      animation: drift,
      builder: (context, child) {
        final dx = drift.value.dx * screenSize.width;
        final dy = drift.value.dy * screenSize.height;

        return Positioned(
          left: baseLeft + dx,
          top: baseTop + dy,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color,
                  blurRadius: blurSigma,
                  spreadRadius: size * 0.2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlowLayer(bool isDark) {
    return AnimatedBuilder(
      animation: Listenable.merge([_nameController, _glowController]),
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            if (_glowController.isAnimating || _glowController.value > 0)
              Container(
                width: 260,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isDark ? Colors.teal.shade400 : Colors.teal.shade300)
                              .withOpacity(_glowAnim.value),
                      blurRadius: 60,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
            FadeTransition(
              opacity: _nameFade,
              child: Transform.scale(
                scale: _nameSpring.value,
                child: ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [Colors.teal.shade300, Colors.cyan.shade300]
                          : [Colors.teal.shade700, Colors.teal.shade500],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.srcIn,
                  child: Text(
                    AppConstants.appName,
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2.5,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
