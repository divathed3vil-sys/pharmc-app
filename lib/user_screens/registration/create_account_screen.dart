import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants.dart';
import '../../services/auth_service.dart';
import 'language_selection_screen.dart';
import 'login_screen.dart';

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

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

String _stripPhoneSpaces(String formatted) =>
    formatted.replaceAll(RegExp(r'\D'), '');

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  DateTime? _dob;
  bool _isLoading = false;
  String? _error;

  late AnimationController _anim;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  String get _rawPhone => _stripPhoneSpaces(_phoneController.text);

  int? get _age {
    if (_dob == null) return null;
    final now = DateTime.now();
    int age = now.year - _dob!.year;
    if (now.month < _dob!.month ||
        (now.month == _dob!.month && now.day < _dob!.day)) {
      age--;
    }
    return age;
  }

  bool get _canSubmit =>
      _nameController.text.trim().length >= 2 &&
      _rawPhone.length == 9 &&
      _dob != null &&
      _age != null &&
      _age! >= 18 &&
      !_isLoading;

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
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDOB() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20),
      firstDate: DateTime(1920),
      lastDate: now,
    );

    if (picked != null) {
      setState(() => _dob = picked);
    }
  }

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await AuthService.signUp(
      phone: _rawPhone,
      fullName: _nameController.text.trim(),
      dateOfBirth: _dob!.toIso8601String().split('T')[0],
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
      setState(() => _error = result.message);
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

    return Scaffold(
      backgroundColor: bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Stack(
        children: [
          // 🔹 Background blobs
          Positioned(
            top: -120,
            right: -100,
            child: _blob(Colors.teal.withOpacity(0.25), 350),
          ),
          Positioned(
            bottom: -120,
            left: -100,
            child: _blob(Colors.indigo.withOpacity(0.20), 350),
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
                                "Create Account",
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: text,
                                ),
                              ),

                              const SizedBox(height: 24),

                              _input(
                                controller: _nameController,
                                hint: "Full Name",
                              ),

                              const SizedBox(height: 16),

                              GestureDetector(
                                onTap: _pickDOB,
                                child: Container(
                                  height: 56,
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey.withOpacity(0.4),
                                    ),
                                  ),
                                  child: Text(
                                    _dob == null
                                        ? "Date of Birth"
                                        : "${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _dob == null ? Colors.grey : text,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              _phoneInput(),

                              if (_error != null) ...[
                                const SizedBox(height: 16),
                                Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ],

                              const SizedBox(height: 24),

                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _canSubmit ? _register : null,
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
                                          "Create Account",
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
                                    Navigator.pushReplacement(
                                      context,
                                      _smoothRoute(const LoginScreen()),
                                    );
                                  },
                                  child: const Text(
                                    "Already have an account? Log in",
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

  Widget _input({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _phoneInput() {
    return TextField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      inputFormatters: [_PhoneSpaceFormatter()],
      decoration: InputDecoration(
        prefixText: "+94 ",
        hintText: "77 123 4567",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
