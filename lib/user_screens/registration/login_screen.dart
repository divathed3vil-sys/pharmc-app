import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants.dart';
import '../../services/auth_service.dart';
import 'create_account_screen.dart';
import 'join_shared_account_screen.dart';
import 'blocked_account_screen.dart';
import '../main_navigation.dart';

/// Formats raw digits as "XXX XXX XXX" (groups of 3).
class _PhoneSpaceFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Strip all non-digit characters
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Limit to 9 digits
    final trimmed = digitsOnly.length > 9
        ? digitsOnly.substring(0, 9)
        : digitsOnly;

    // Format as "XXX XXX XXX"
    final buffer = StringBuffer();
    for (int i = 0; i < trimmed.length; i++) {
      if (i > 0 && i % 3 == 0) buffer.write(' ');
      buffer.write(trimmed[i]);
    }

    final formatted = buffer.toString();

    // Calculate new cursor position
    // Map the raw cursor offset in newValue to the formatted string
    int rawCursor = newValue.selection.baseOffset;
    // Count how many digits are before rawCursor in the new (unformatted) text
    int digitsBefore = newValue.text
        .substring(0, rawCursor.clamp(0, newValue.text.length))
        .replaceAll(RegExp(r'\D'), '')
        .length;
    digitsBefore = digitsBefore.clamp(0, trimmed.length);

    // Walk through formatted string to find position after `digitsBefore` digits
    int formattedCursor = 0;
    int counted = 0;
    for (int i = 0; i < formatted.length && counted < digitsBefore; i++) {
      formattedCursor = i + 1;
      if (formatted[i] != ' ') counted++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: formattedCursor.clamp(0, formatted.length),
      ),
    );
  }
}

/// Extracts raw digits from a formatted phone string.
String _stripPhoneSpaces(String formatted) {
  return formatted.replaceAll(RegExp(r'\D'), '');
}

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

  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  /// Raw digits extracted from the formatted field.
  String get _rawPhone => _stripPhoneSpaces(_phoneController.text);

  bool get _canLogin {
    final phone = _rawPhone;
    return phone.length == 9 &&
        RegExp(r'^\d{9}$').hasMatch(phone) &&
        !_isRepeatingDigits(phone) &&
        !_isLoading;
  }

  bool _isRepeatingDigits(String phone) {
    if (phone.isEmpty) return false;
    return phone.split('').toSet().length == 1;
  }

  @override
  void initState() {
    super.initState();

    _phoneController.addListener(() => setState(() => _errorMessage = null));

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
    _phoneController.dispose();
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

  // ============ PHONE LOGIN ============

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

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
      // Navigate to BlockedAccountScreen — not inline error
      Navigator.pushAndRemoveUntil(
        context,
        _smoothRoute(BlockedAccountScreen(blockedReason: result.blockedReason)),
        (route) => false,
      );
    } else if (result.needsApproval) {
      setState(() => _errorMessage = result.message);
    } else {
      setState(() => _errorMessage = result.message);
    }
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
                              'Log in with your phone number.',
                              style: TextStyle(
                                fontSize: 14,
                                color: sub,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 18),

                            // ── Phone input ──
                            _phoneInput(isDark: isDark, text: text, sub: sub),

                            if (_rawPhone.length == 9 &&
                                _isRepeatingDigits(_rawPhone))
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: _miniAlert(
                                  isDark: isDark,
                                  message: 'Please enter a valid phone number.',
                                ),
                              ),

                            if (_errorMessage != null) ...[
                              const SizedBox(height: 12),
                              _errorBox(isDark, _errorMessage!),
                            ],

                            const SizedBox(height: 16),

                            // ── Login button ──
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

                            // ── OR divider ──
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.08)
                                        : Colors.black.withOpacity(0.08),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  child: Text(
                                    'or',
                                    style: TextStyle(
                                      color: sub,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.08)
                                        : Colors.black.withOpacity(0.08),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // ── Join Shared Account ──
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: _isLoading
                                    ? null
                                    : () => Navigator.push(
                                        context,
                                        _smoothRoute(
                                          const JoinSharedAccountScreen(),
                                        ),
                                      ),
                                icon: Icon(
                                  Icons.group_add_rounded,
                                  size: 20,
                                  color: Colors.purple.shade400,
                                ),
                                label: Text(
                                  'Join Shared Account',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    color: Colors.purple.shade400,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Colors.purple.shade400.withOpacity(
                                      0.35,
                                    ),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  backgroundColor: Colors.purple.withOpacity(
                                    isDark ? 0.08 : 0.04,
                                  ),
                                ),
                              ),
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

  // ============ SHARED WIDGETS ============

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
              enabled: !_isLoading,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d ]')),
                _PhoneSpaceFormatter(),
              ],
              style: TextStyle(
                color: text,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: 'Phone number',
                hintStyle: TextStyle(
                  color: sub,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
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
}
