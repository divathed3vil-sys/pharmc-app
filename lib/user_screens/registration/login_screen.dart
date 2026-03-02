import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants.dart';
import '../../services/auth_service.dart';
import 'create_account_screen.dart';
import 'join_shared_account_screen.dart';
import 'blocked_account_screen.dart';
import '../main_navigation.dart';

class _PhoneSpaceFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    final trimmed = digitsOnly.length > 9
        ? digitsOnly.substring(0, 9)
        : digitsOnly;

    final buffer = StringBuffer();
    for (int i = 0; i < trimmed.length; i++) {
      if (i > 0 && i % 3 == 0) buffer.write(' ');
      buffer.write(trimmed[i]);
    }

    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

String _stripPhoneSpaces(String formatted) =>
    formatted.replaceAll(RegExp(r'\D'), '');

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _anim;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  String get _rawPhone => _stripPhoneSpaces(_phoneController.text);

  bool get _canLogin =>
      _rawPhone.length == 9 &&
      !_isLoading &&
      !_rawPhone.split('').every((c) => c == _rawPhone[0]);

  @override
  void initState() {
    super.initState();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));

    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await AuthService.signIn(phone: _rawPhone);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      Navigator.pushAndRemoveUntil(
        context,
        _smoothRoute(const MainNavigation()),
        (route) => false,
      );
    } else if (result.isBlocked) {
      Navigator.pushAndRemoveUntil(
        context,
        _smoothRoute(BlockedAccountScreen(blockedReason: result.blockedReason)),
        (route) => false,
      );
    } else {
      setState(() => _errorMessage = result.message);
    }
  }

  Route _smoothRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF6F8FA);
    final text = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final sub = Colors.grey.shade500;

    return Scaffold(
      backgroundColor: bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Stack(
        children: [
          // 🔹 Full Screen Blobs
          Positioned(
            top: -120,
            right: -100,
            child: _blob(Colors.teal.withOpacity(0.25), 350),
          ),
          Positioned(
            bottom: -120,
            left: -100,
            child: _blob(Colors.blue.withOpacity(0.20), 350),
          ),

          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),

                        Text(
                          AppConstants.appName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.teal.shade400,
                          ),
                        ),

                        const SizedBox(height: 40),

                        _glassCard(
                          isDark,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Welcome Back",
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: text,
                                ),
                              ),

                              const SizedBox(height: 24),

                              _phoneInput(isDark, text),

                              if (_errorMessage != null) ...[
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),

                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _canLogin ? _login : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal.shade600,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : const Text(
                                          "Log In",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      _smoothRoute(const CreateAccountScreen()),
                                    );
                                  },
                                  child: Text(
                                    "Don't have an account? Register",
                                    style: TextStyle(
                                      color: sub,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(Color color, double size) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(width: size, height: size, color: color),
      ),
    );
  }

  Widget _glassCard(bool isDark, Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.2),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _phoneInput(bool isDark, Color text) {
    return TextField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      inputFormatters: [_PhoneSpaceFormatter()],
      style: TextStyle(color: text, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        prefixText: "+94 ",
        hintText: "77 123 4567",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
