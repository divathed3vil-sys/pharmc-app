import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/preferences_service.dart';
import 'role_selection_screen.dart';
import '../user_screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scale;

  bool _exiting = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeIn = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _scale = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _startSequence();
  }

  void _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 400));

    _controller.forward();

    await Future.delayed(const Duration(milliseconds: 2800));

    if (mounted) {
      setState(() {
        _exiting = true;
      });

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        // Decide where to go
        final bool registered = PreferencesService.isRegistered();

        Widget destination;
        if (registered) {
          destination = const HomeScreen();
        } else {
          destination = const RoleSelectionScreen();
        }

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                destination,
            transitionDuration: const Duration(milliseconds: 600),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: _exiting ? 0.0 : 1.0,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 500),
            offset: _exiting ? const Offset(0, -0.05) : Offset.zero,
            curve: Curves.easeInCubic,
            child: ScaleTransition(
              scale: _scale,
              child: FadeTransition(
                opacity: _fadeIn,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppConstants.appName,
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w800,
                        color: Colors.teal.shade700,
                        letterSpacing: -2.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Medicine, delivered.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade400,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
