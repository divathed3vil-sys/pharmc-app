import 'dart:ui';
import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../services/auth_service.dart';
import 'create_account_screen.dart';
import '../main_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool get _canLogin =>
      _emailController.text.trim().contains('@') &&
      _emailController.text.trim().contains('.') &&
      _passwordController.text.trim().length >= 6 &&
      !_isLoading;

  @override
  void initState() {
    super.initState();

    _emailController.addListener(() => setState(() => _errorMessage = null));
    _passwordController.addListener(() => setState(() => _errorMessage = null));

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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await AuthService.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      Navigator.pushAndRemoveUntil(
        context,
        _smoothRoute(const MainNavigation()),
        (route) => false,
      );
    } else {
      setState(() => _errorMessage = result.message);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      setState(() {
        _errorMessage = 'Enter your email above, then tap Forgot Password.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await AuthService.resetPassword(email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success
            ? Colors.teal.shade600
            : Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA);
    final text = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: SafeArea(
            child: Stack(
              children: [
                // subtle background blobs (very light)
                Positioned(
                  top: -120,
                  right: -140,
                  child: _blurBlob(
                    color: Colors.teal.withOpacity(isDark ? 0.20 : 0.14),
                    size: 260,
                  ),
                ),
                Positioned(
                  bottom: -140,
                  left: -120,
                  child: _blurBlob(
                    color: Colors.blue.withOpacity(isDark ? 0.16 : 0.12),
                    size: 260,
                  ),
                ),

                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Brand
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
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

                      const SizedBox(height: 16),

                      // Glass card
                      _glassCard(
                        isDark: isDark,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: text,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Log in to continue.',
                              style: TextStyle(
                                fontSize: 14,
                                color: sub,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 18),

                            _input(
                              isDark: isDark,
                              text: text,
                              sub: sub,
                              controller: _emailController,
                              icon: Icons.email_outlined,
                              hint: 'Email address',
                              keyboardType: TextInputType.emailAddress,
                              enabled: !_isLoading,
                            ),
                            const SizedBox(height: 12),
                            _input(
                              isDark: isDark,
                              text: text,
                              sub: sub,
                              controller: _passwordController,
                              icon: Icons.lock_outline_rounded,
                              hint: 'Password',
                              keyboardType: TextInputType.visiblePassword,
                              enabled: !_isLoading,
                              obscure: _obscurePassword,
                              suffix: GestureDetector(
                                onTap: _isLoading
                                    ? null
                                    : () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                child: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: sub,
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: _isLoading ? null : _forgotPassword,
                                child: Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.teal.shade400,
                                  ),
                                ),
                              ),
                            ),

                            if (_errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(
                                    isDark ? 0.18 : 0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.22),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      color: Colors.red.shade300,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.red.shade200
                                              : Colors.red.shade700,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),

                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _canLogin ? _login : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal.shade600,
                                  disabledBackgroundColor: isDark
                                      ? Colors.white.withOpacity(0.10)
                                      : Colors.grey.shade200,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Log In',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Secondary actions
                            Row(
                              children: [
                                Expanded(
                                  child: _outlineButton(
                                    isDark: isDark,
                                    label: 'Google',
                                    icon: Icons.g_mobiledata_rounded,
                                    onTap: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            'Google sign-in coming soon',
                                          ),
                                          backgroundColor: Colors.teal.shade600,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _outlineButton(
                                    isDark: isDark,
                                    label: 'Apple',
                                    icon: Icons.apple_rounded,
                                    onTap: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            'Apple sign-in coming soon',
                                          ),
                                          backgroundColor: Colors.teal.shade600,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Center(
                        child: GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () => Navigator.push(
                                  context,
                                  _smoothRoute(const CreateAccountScreen()),
                                ),
                          child: RichText(
                            text: TextSpan(
                              text: "Don't have an account? ",
                              style: TextStyle(
                                fontSize: 14,
                                color: sub,
                                fontWeight: FontWeight.w600,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Register',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.teal.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
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

  Widget _input({
    required bool isDark,
    required Color text,
    required Color sub,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required TextInputType keyboardType,
    required bool enabled,
    bool obscure = false,
    Widget? suffix,
  }) {
    final inputBg = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.03);

    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.10)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: TextStyle(color: text, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: sub, fontWeight: FontWeight.w600),
          prefixIcon: Icon(icon, color: sub),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _outlineButton({
    required bool isDark,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final border = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.black.withOpacity(0.08);

    final fg = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.white.withOpacity(0.70),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: fg),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: fg, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
