import 'dart:ui';
import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../services/auth_service.dart';
import 'language_selection_screen.dart';
import 'login_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen>
    with SingleTickerProviderStateMixin {
  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  // Phone validation: repeating digits like 111111111
  bool _isRepeatingDigits(String phone) {
    if (phone.isEmpty) return false;
    return phone.split('').toSet().length == 1;
  }

  // Strong password
  String? _validatePassword(String password) {
    if (password.isEmpty) return null;
    if (password.length < 8) return 'At least 8 characters';
    if (!password.contains(RegExp(r'[A-Z]'))) return 'Add an uppercase letter';
    if (!password.contains(RegExp(r'[a-z]'))) return 'Add a lowercase letter';
    if (!password.contains(RegExp(r'[0-9]'))) return 'Add a number';
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Add a special character';
    }
    return null;
  }

  bool get _canSubmit {
    final phone = _phoneController.text.trim();
    final pass = _passwordController.text.trim();

    return _nameController.text.trim().length >= 2 &&
        phone.length == 9 &&
        RegExp(r'^\d{9}$').hasMatch(phone) &&
        !_isRepeatingDigits(phone) &&
        _emailController.text.trim().contains('@') &&
        _emailController.text.trim().contains('.') &&
        pass.isNotEmpty &&
        _validatePassword(pass) == null &&
        !_isLoading;
  }

  @override
  void initState() {
    super.initState();

    _nameController.addListener(_refresh);
    _phoneController.addListener(_refresh);
    _emailController.addListener(_refresh);
    _passwordController.addListener(_refresh);

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

  void _refresh() => setState(() => _errorMessage = null);

  @override
  void dispose() {
    _anim.dispose();
    _nameController.dispose();
    _phoneController.dispose();
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

  Future<void> _createAccount() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    const role = 'customer';

    final result = await AuthService.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      role: role,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      Navigator.pushReplacement(
        context,
        _smoothRoute(const LanguageSelectionScreen()),
      );
    } else {
      setState(() => _errorMessage = result.message);
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
          icon: Icon(Icons.arrow_back_rounded, color: text),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: SafeArea(
            child: Stack(
              children: [
                // background blobs
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
                    color: Colors.indigo.withOpacity(isDark ? 0.16 : 0.12),
                    size: 260,
                  ),
                ),

                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
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
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      _glassCard(
                        isDark: isDark,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create account',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: text,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Start with a demo account. Verify later to place real orders.',
                              style: TextStyle(
                                fontSize: 13,
                                color: sub,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 18),

                            _input(
                              isDark: isDark,
                              text: text,
                              sub: sub,
                              controller: _nameController,
                              icon: Icons.person_outline_rounded,
                              hint: 'Full name',
                              keyboardType: TextInputType.name,
                              enabled: !_isLoading,
                            ),
                            const SizedBox(height: 12),

                            _phoneInput(isDark: isDark, text: text, sub: sub),
                            if (_phoneController.text.trim().length == 9 &&
                                _isRepeatingDigits(
                                  _phoneController.text.trim(),
                                ))
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: _miniAlert(
                                  isDark: isDark,
                                  message: 'Please enter a valid phone number.',
                                ),
                              ),

                            const SizedBox(height: 12),

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
                              hint: 'Strong password',
                              keyboardType: TextInputType.visiblePassword,
                              enabled: !_isLoading,
                              obscure: _obscurePassword,
                              suffix: IconButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: sub,
                                ),
                              ),
                            ),

                            if (_passwordController.text.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _passwordStrength(isDark, text, sub),
                            ],

                            if (_errorMessage != null) ...[
                              const SizedBox(height: 12),
                              _errorBox(isDark, _errorMessage!),
                            ],

                            const SizedBox(height: 16),

                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _canSubmit ? _createAccount : null,
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
                                        'Create Account',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            Row(
                              children: [
                                Expanded(
                                  child: _outlineButton(
                                    isDark: isDark,
                                    label: 'Google',
                                    icon: Icons.g_mobiledata_rounded,
                                    onTap: () => _soonSnack(
                                      'Google sign-in coming soon',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _outlineButton(
                                    isDark: isDark,
                                    label: 'Apple',
                                    icon: Icons.apple_rounded,
                                    onTap: () =>
                                        _soonSnack('Apple sign-in coming soon'),
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
                              : () => Navigator.pushReplacement(
                                  context,
                                  _smoothRoute(const LoginScreen()),
                                ),
                          child: RichText(
                            text: TextSpan(
                              text: 'Already have an account? ',
                              style: TextStyle(
                                fontSize: 14,
                                color: sub,
                                fontWeight: FontWeight.w600,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Log in',
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

  void _soonSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.teal.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _phoneInput({
    required bool isDark,
    required Color text,
    required Color sub,
  }) {
    final inputBg = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.03);
    final border = isDark
        ? Colors.white.withOpacity(0.10)
        : Colors.black.withOpacity(0.06);

    return Row(
      children: [
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              bottomLeft: Radius.circular(18),
            ),
            border: Border.all(color: border),
          ),
          child: Center(
            child: Text(
              '+94',
              style: TextStyle(color: text, fontWeight: FontWeight.w900),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: border),
            ),
            child: TextField(
              controller: _phoneController,
              maxLength: 9,
              enabled: !_isLoading,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: text, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                counterText: '',
                hintText: '771234567',
                hintStyle: TextStyle(color: sub, fontWeight: FontWeight.w600),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _passwordStrength(bool isDark, Color text, Color sub) {
    final password = _passwordController.text;

    bool hasLen = password.length >= 8;
    bool hasUpper = password.contains(RegExp(r'[A-Z]'));
    bool hasLower = password.contains(RegExp(r'[a-z]'));
    bool hasNum = password.contains(RegExp(r'[0-9]'));
    bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    Widget row(String t, bool ok) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(
              ok ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 16,
              color: ok ? Colors.green.shade500 : sub,
            ),
            const SizedBox(width: 8),
            Text(
              t,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: ok ? Colors.green.shade500 : sub,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          row('At least 8 characters', hasLen),
          row('Uppercase letter', hasUpper),
          row('Lowercase letter', hasLower),
          row('Number', hasNum),
          row('Special character', hasSpecial),
        ],
      ),
    );
  }

  Widget _miniAlert({required bool isDark, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: Colors.red.shade300,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isDark ? Colors.red.shade200 : Colors.red.shade700,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBox(bool isDark, String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.22)),
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
              msg,
              style: TextStyle(
                color: isDark ? Colors.red.shade200 : Colors.red.shade700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
