import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants.dart';
import '../../services/auth_service.dart';
import 'language_selection_screen.dart';
import 'login_screen.dart';
import 'join_shared_account_screen.dart';

/// Formats raw digits as "XXX XXX XXX" (groups of 3).
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

    int rawCursor = newValue.selection.baseOffset;
    int digitsBefore = newValue.text
        .substring(0, rawCursor.clamp(0, newValue.text.length))
        .replaceAll(RegExp(r'\D'), '')
        .length;
    digitsBefore = digitsBefore.clamp(0, trimmed.length);

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

String _stripPhoneSpaces(String formatted) {
  return formatted.replaceAll(RegExp(r'\D'), '');
}

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  DateTime? _selectedDateOfBirth;
  bool _isLoading = false;
  String? _errorMessage;

  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  String get _rawPhone => _stripPhoneSpaces(_phoneController.text);

  bool _isRepeatingDigits(String phone) {
    if (phone.isEmpty) return false;
    return phone.split('').toSet().length == 1;
  }

  int? get _calculatedAge {
    if (_selectedDateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - _selectedDateOfBirth!.year;
    if (now.month < _selectedDateOfBirth!.month ||
        (now.month == _selectedDateOfBirth!.month &&
            now.day < _selectedDateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  bool get _canSubmit {
    final phone = _rawPhone;
    final age = _calculatedAge;

    return _nameController.text.trim().length >= 2 &&
        phone.length == 9 &&
        RegExp(r'^\d{9}$').hasMatch(phone) &&
        !_isRepeatingDigits(phone) &&
        _selectedDateOfBirth != null &&
        age != null &&
        age >= 18 &&
        !_isLoading;
  }

  @override
  void initState() {
    super.initState();

    _nameController.addListener(_refresh);
    _phoneController.addListener(_refresh);

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

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initialDate =
        _selectedDateOfBirth ?? DateTime(now.year - 20, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'Select your date of birth',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: Colors.teal.shade600),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateOfBirth = picked;
        _errorMessage = null;
      });
    }
  }

  Future<void> _createAccount() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await AuthService.signUp(
      phone: _rawPhone,
      fullName: _nameController.text.trim(),
      dateOfBirth: _selectedDateOfBirth!.toIso8601String().split('T')[0],
      role: 'customer',
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

                            // ── Full name ──
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

                            // ── Date of birth ──
                            _dateOfBirthPicker(isDark, text, sub),
                            if (_calculatedAge != null && _calculatedAge! < 18)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: _miniAlert(
                                  isDark: isDark,
                                  message: 'You must be at least 18 years old.',
                                ),
                              ),

                            const SizedBox(height: 12),

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

                            // ── Create Account button ──
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

                            // ── Join Shared Account link ──
                            Center(
                              child: GestureDetector(
                                onTap: _isLoading
                                    ? null
                                    : () => Navigator.push(
                                        context,
                                        _smoothRoute(
                                          const JoinSharedAccountScreen(),
                                        ),
                                      ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withOpacity(
                                      isDark ? 0.08 : 0.04,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.purple.withOpacity(0.15),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.group_add_rounded,
                                        size: 16,
                                        color: Colors.purple.shade400,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Join Shared Account instead',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.purple.shade400,
                                        ),
                                      ),
                                    ],
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

  // ============ DATE OF BIRTH PICKER ============

  Widget _dateOfBirthPicker(bool isDark, Color text, Color sub) {
    final inputBg = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.03);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.10)
        : Colors.black.withOpacity(0.06);

    final hasDate = _selectedDateOfBirth != null;
    final age = _calculatedAge;

    return GestureDetector(
      onTap: _isLoading ? null : _pickDateOfBirth,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: inputBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(Icons.cake_outlined, color: sub, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasDate
                    ? '${_selectedDateOfBirth!.year}-'
                          '${_selectedDateOfBirth!.month.toString().padLeft(2, '0')}-'
                          '${_selectedDateOfBirth!.day.toString().padLeft(2, '0')}'
                    : 'Date of birth',
                style: TextStyle(
                  color: hasDate ? text : sub,
                  fontWeight: hasDate ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
            if (hasDate && age != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: age >= 18
                      ? Colors.green.withOpacity(isDark ? 0.15 : 0.10)
                      : Colors.red.withOpacity(isDark ? 0.15 : 0.10),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: age >= 18
                        ? Colors.green.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  'Age: $age',
                  style: TextStyle(
                    color: age >= 18
                        ? Colors.green.shade500
                        : Colors.red.shade500,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
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

  Widget _input({
    required bool isDark,
    required Color text,
    required Color sub,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required TextInputType keyboardType,
    required bool enabled,
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
        keyboardType: keyboardType,
        style: TextStyle(color: text, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: sub, fontWeight: FontWeight.w600),
          prefixIcon: Icon(icon, color: sub),
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
