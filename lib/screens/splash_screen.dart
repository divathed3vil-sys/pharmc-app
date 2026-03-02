import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../services/auth_service.dart';
import '../user_screens/main_navigation.dart';
import '../user_screens/registration/blocked_account_screen.dart';
import '../user_screens/registration/create_account_screen.dart';
import '../user_screens/registration/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _blobController;
  late final Animation<Offset> _blob1Drift;
  late final Animation<Offset> _blob2Drift;
  late final Animation<Offset> _blob3Drift;

  late final AnimationController _rippleController;
  late final Animation<double> _rippleScale;
  late final Animation<double> _rippleFade;

  late final AnimationController _nameController;

  late final AnimationController _glowController;
  late final Animation<double> _glowAnim;

  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerPos; // 0..1 usable

  late final AnimationController _subtitleController;
  late final Animation<double> _subtitleFade;
  late final Animation<Offset> _subtitleSlide;

  late final AnimationController _particleController;

  late final AnimationController _exitController;
  late final Animation<double> _exitFade;
  late final Animation<double> _exitScale;

  static const String _appName = AppConstants.appName;

  @override
  void initState() {
    super.initState();

    // Blobs
    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );
    _blob1Drift =
        Tween<Offset>(
          begin: const Offset(-0.04, -0.03),
          end: const Offset(0.04, 0.03),
        ).animate(
          CurvedAnimation(parent: _blobController, curve: Curves.easeInOutSine),
        );
    _blob2Drift =
        Tween<Offset>(
          begin: const Offset(0.03, 0.04),
          end: const Offset(-0.03, -0.02),
        ).animate(
          CurvedAnimation(parent: _blobController, curve: Curves.easeInOutSine),
        );
    _blob3Drift =
        Tween<Offset>(
          begin: const Offset(0.02, -0.04),
          end: const Offset(-0.04, 0.03),
        ).animate(
          CurvedAnimation(parent: _blobController, curve: Curves.easeInOutSine),
        );
    _blobController.repeat(reverse: true);

    // Ripple
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _rippleScale = Tween<double>(begin: 0.0, end: 2.8).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );
    _rippleFade = Tween<double>(
      begin: 0.55,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _rippleController, curve: Curves.easeIn));

    // Letters
    _nameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // Glow
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _glowAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 0.70,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.70,
          end: 0.25,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 8,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.25,
          end: 0.50,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.50,
          end: 0.08,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(tween: Tween(begin: 0.08, end: 0.08), weight: 50),
    ]).animate(_glowController);

    // Shimmer (keep it in a safe 0..1 range)
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _shimmerPos = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Subtitle
    _subtitleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _subtitleController, curve: Curves.easeOut),
    );
    _subtitleSlide =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _subtitleController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Particles
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _particleController.repeat(reverse: true);

    // Exit
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
    );
    _exitScale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
    );

    _startSequence();
  }

  void _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    _rippleController.forward();
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;

    _nameController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    _glowController.repeat(reverse: false);

    // Shimmer AFTER most letters are visible (prevents ugly overlay moments)
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    _shimmerController.forward(from: 0);

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _subtitleController.forward();

    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;

    _exitController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    Widget destination;
    try {
      final sessionResult = await AuthService.validateSession();

      if (sessionResult.valid) {
        destination = const MainNavigation();
      } else if (sessionResult.reason == 'blocked') {
        destination = BlockedAccountScreen(
          blockedReason: sessionResult.blockedReason,
        );
      } else if (sessionResult.reason == 'no_device') {
        // REQUIRED: first install -> open Register screen
        destination = const CreateAccountScreen();
      } else {
        destination = const LoginScreen();
      }
    } catch (_) {
      destination = const LoginScreen();
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
    _rippleController.dispose();
    _nameController.dispose();
    _glowController.dispose();
    _shimmerController.dispose();
    _subtitleController.dispose();
    _particleController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF080B0F) : const Color(0xFFF4F7FA);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: bg,
      body: AnimatedBuilder(
        animation: Listenable.merge([_exitController, _blobController]),
        builder: (context, _) {
          return FadeTransition(
            opacity: _exitFade,
            child: ScaleTransition(
              scale: _exitScale,
              child: Stack(
                children: [
                  _blob(
                    size: size,
                    drift: _blob1Drift,
                    baseLeft: -90,
                    baseTop: size.height * 0.12,
                    blobSize: 320,
                    color: isDark
                        ? Colors.teal.shade900.withOpacity(0.40)
                        : Colors.teal.shade200.withOpacity(0.35),
                    blur: 70,
                  ),
                  _blob(
                    size: size,
                    drift: _blob2Drift,
                    baseLeft: size.width - 110,
                    baseTop: size.height * 0.52,
                    blobSize: 260,
                    color: isDark
                        ? Colors.cyan.shade900.withOpacity(0.30)
                        : Colors.cyan.shade100.withOpacity(0.40),
                    blur: 60,
                  ),
                  _blob(
                    size: size,
                    drift: _blob3Drift,
                    baseLeft: size.width * 0.25,
                    baseTop: -70,
                    blobSize: 240,
                    color: isDark
                        ? Colors.teal.shade800.withOpacity(0.22)
                        : Colors.teal.shade100.withOpacity(0.30),
                    blur: 65,
                  ),
                  ..._buildParticles(size, isDark),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLogoStack(isDark),
                        const SizedBox(height: 20),
                        SlideTransition(
                          position: _subtitleSlide,
                          child: FadeTransition(
                            opacity: _subtitleFade,
                            child: Text(
                              'Project by Harish & Diva.',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade400,
                                letterSpacing: 1.2,
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

  Widget _buildLogoStack(bool isDark) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _rippleController,
        _nameController,
        _glowController,
        _shimmerController,
      ]),
      builder: (context, _) {
        return SizedBox(
          width: 280,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_rippleController.value > 0 && _rippleController.value < 1)
                Transform.scale(
                  scale: _rippleScale.value,
                  child: Container(
                    width: 80,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color:
                            (isDark
                                    ? Colors.teal.shade400
                                    : Colors.teal.shade500)
                                .withOpacity(_rippleFade.value),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

              // Glow
              Container(
                width: 300,
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(70),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isDark ? Colors.teal.shade400 : Colors.teal.shade400)
                              .withOpacity(_glowAnim.value),
                      blurRadius: 80,
                      spreadRadius: 6,
                    ),
                  ],
                ),
              ),

              // Logo + shimmer (fixed: shimmer only draws on letters, no white box)
              ClipRect(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildAnimatedLetters(isDark: isDark, asWhiteText: false),

                    if (_shimmerController.isAnimating ||
                        _shimmerController.value > 0)
                      Opacity(
                        opacity: isDark ? 0.55 : 0.70,
                        child: ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (bounds) {
                            final center = _shimmerPos.value.clamp(0.0, 1.0);
                            final left = (center - 0.18).clamp(0.0, 1.0);
                            final right = (center + 0.18).clamp(0.0, 1.0);

                            return LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: const [
                                Colors.transparent,
                                Colors.white,
                                Colors.transparent,
                              ],
                              stops: [left, center, right],
                            ).createShader(bounds);
                          },
                          child: _buildAnimatedLetters(
                            isDark: isDark,
                            asWhiteText: true,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedLetters({
    required bool isDark,
    required bool asWhiteText,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_appName.length, (i) {
        final start = (i * 0.10).clamp(0.0, 0.9);
        final end = (start + 0.55).clamp(0.0, 1.0);

        final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _nameController,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        );
        final slide = Tween<double>(begin: 22.0, end: 0.0).animate(
          CurvedAnimation(
            parent: _nameController,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          ),
        );
        final scale = Tween<double>(begin: 0.55, end: 1.0).animate(
          CurvedAnimation(
            parent: _nameController,
            curve: Interval(start, end, curve: Curves.elasticOut),
          ),
        );

        return AnimatedBuilder(
          animation: _nameController,
          builder: (_, __) {
            final letter = Text(
              _appName[i],
              style: TextStyle(
                fontSize: 62,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.5,
                height: 1.0,
                color: asWhiteText ? Colors.white : null,
              ),
            );

            return Opacity(
              opacity: fade.value,
              child: Transform.translate(
                offset: Offset(0, slide.value),
                child: Transform.scale(
                  scale: scale.value,
                  child: asWhiteText
                      ? letter
                      : ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDark
                                  ? [
                                      Colors.teal.shade200,
                                      Colors.cyan.shade300,
                                      Colors.teal.shade300,
                                    ]
                                  : [
                                      Colors.teal.shade600,
                                      Colors.teal.shade800,
                                      Colors.teal.shade600,
                                    ],
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.srcIn,
                          child: letter,
                        ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  static const _particleData = [
    [0.15, 0.25, 5.0, 0.0, 0.06],
    [0.82, 0.18, 4.0, 0.5, 0.05],
    [0.72, 0.72, 6.0, 0.3, 0.07],
    [0.22, 0.78, 3.5, 0.8, 0.04],
    [0.50, 0.88, 4.5, 0.2, 0.05],
    [0.88, 0.50, 3.0, 0.7, 0.06],
  ];

  List<Widget> _buildParticles(Size size, bool isDark) {
    return _particleData.map((p) {
      return AnimatedBuilder(
        animation: _particleController,
        builder: (_, __) {
          final t = (_particleController.value + p[3]) % 1.0;
          final dy = math.sin(t * math.pi * 2) * 18 * p[4] * 10;
          final dx = math.cos(t * math.pi * 2) * 8 * p[4] * 10;
          final opacity = (0.25 + 0.20 * math.sin(t * math.pi * 2)).clamp(
            0.0,
            1.0,
          );

          return Positioned(
            left: size.width * p[0] + dx,
            top: size.height * p[1] + dy,
            child: Container(
              width: p[2],
              height: p[2],
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? Colors.teal.shade400 : Colors.teal.shade500)
                    .withOpacity(opacity),
                boxShadow: [
                  BoxShadow(
                    color:
                        (isDark ? Colors.teal.shade400 : Colors.teal.shade400)
                            .withOpacity(opacity * 0.6),
                    blurRadius: p[2] * 2.5,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _blob({
    required Size size,
    required Animation<Offset> drift,
    required double baseLeft,
    required double baseTop,
    required double blobSize,
    required Color color,
    required double blur,
  }) {
    return AnimatedBuilder(
      animation: drift,
      builder: (_, __) {
        return Positioned(
          left: baseLeft + drift.value.dx * size.width,
          top: baseTop + drift.value.dy * size.height,
          child: Container(
            width: blobSize,
            height: blobSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color,
                  blurRadius: blur,
                  spreadRadius: blobSize * 0.22,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
