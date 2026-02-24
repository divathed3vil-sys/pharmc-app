import 'package:flutter/material.dart';
import '../constants.dart';
import 'role_selection_screen.dart';
import '../services/auth_service.dart';
import '../services/preferences_service.dart';
import '../user_screens/main_navigation.dart';
import '../main.dart';

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

    if (!mounted) return;

    setState(() => _exiting = true);

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // ── Auth check ────────────────────────────────────────────────────────
    // We verify the session against the SERVER, not just the local token.
    // This catches cases where the account was deleted from the dashboard
    // or the token has expired/been revoked — and routes to login instead
    // of crashing into the home screen with a dead session.
    Widget destination;

    try {
      // getUser() hits the Supabase API — throws if session is invalid
      final response = await supabase.auth.getUser();
      final user = response.user;

      // Must have a real, email-verified user
      if (user != null && user.emailConfirmedAt != null) {
        destination = const MainNavigation();
      } else {
        // Logged in but email not verified — clear stale state and send to login
        await _clearStaleSession();
        destination = const RoleSelectionScreen();
      }
    } catch (_) {
      // getUser() threw — session is dead (account deleted, token revoked, etc.)
      await _clearStaleSession();
      destination = const RoleSelectionScreen();
    }
    // ──────────────────────────────────────────────────────────────────────

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  /// Wipes the local Supabase session + all cached preferences so we start
  /// completely clean the next time a user logs in.
  Future<void> _clearStaleSession() async {
    try {
      await supabase.auth.signOut();
    } catch (_) {
      // signOut can also throw if the token is already dead — that's fine,
      // we just want the local state gone.
    }
    await PreferencesService.clearAll();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                      'Project by Harish & Diva.',
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
