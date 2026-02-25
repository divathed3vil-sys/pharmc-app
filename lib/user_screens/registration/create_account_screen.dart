import 'package:flutter/material.dart';
//import '../../../constants.dart';
import '../../../services/auth_service.dart';
import '../../../services/preferences_service.dart';
import 'email_verification_screen.dart';
//import 'login_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen>
    with SingleTickerProviderStateMixin {
  // ================================
  // CONTROLLERS
  // ================================
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeIn;

  // ============================================================
  // ✅ PHONE VALIDATION: Detect repeating digits like 111111111
  // ============================================================
  bool _isRepeatingDigits(String phone) {
    if (phone.isEmpty) return false;
    return phone.split('').toSet().length == 1;
  }

  // ============================================================
  // ✅ PASSWORD VALIDATION (Strong Password Policy)
  // ============================================================
  String? _validatePassword(String password) {
    if (password.isEmpty) return null;
    if (password.length < 8) return 'Password must be at least 8 characters';
    if (!password.contains(RegExp(r'[A-Z]')))
      return 'Include at least one uppercase letter';
    if (!password.contains(RegExp(r'[a-z]')))
      return 'Include at least one lowercase letter';
    if (!password.contains(RegExp(r'[0-9]')))
      return 'Include at least one number';
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Include at least one special character';
    }
    return null;
  }

  // ============================================================
  // ✅ SUBMIT VALIDATION
  // ============================================================
  bool get _canSubmit {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    return _nameController.text.trim().length >= 2 &&
        phone.length == 9 &&
        !_isRepeatingDigits(phone) &&
        _emailController.text.trim().contains('@') &&
        _emailController.text.trim().contains('.') &&
        password.isNotEmpty &&
        _validatePassword(password) == null &&
        !_isLoading;
  }

  @override
  void initState() {
    super.initState();

    _nameController.addListener(_refresh);
    _phoneController.addListener(_refresh);
    _emailController.addListener(_refresh);
    _passwordController.addListener(_refresh);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  void _refresh() => setState(() => _errorMessage = null);

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ============================================================
  // ✅ CREATE ACCOUNT FUNCTION
  // ============================================================
  void _createAccount() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    const role = 'customer';
    final email = _emailController.text.trim();

    final result = await AuthService.signUp(
      email: email,
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      role: role,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.success) {
      await PreferencesService.setUserName(_nameController.text.trim());
      await PreferencesService.setUserPhone(_phoneController.text.trim());
      await PreferencesService.setUserEmail(email);
      await PreferencesService.setUserRole(role);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(email: email),
        ),
      );
    } else {
      setState(() => _errorMessage = result.message);
    }
  }

  // ============================================================
  // ✅ BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final inputBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: FadeTransition(
        opacity: _fadeIn,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                Text(
                  'Create your\naccount',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 28),

                // ======================
                // NAME FIELD
                // ======================
                _buildInput(
                  controller: _nameController,
                  focusNode: _nameFocus,
                  nextFocus: _phoneFocus,
                  hint: 'Full name',
                  icon: Icons.person_outline,
                  inputBg: inputBg,
                  textColor: textColor,
                ),

                const SizedBox(height: 12),

                // ======================
                // PHONE FIELD
                // ======================
                Row(
                  children: [
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          bottomLeft: Radius.circular(14),
                        ),
                      ),
                      child: const Center(child: Text('+94')),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        focusNode: _phoneFocus,
                        maxLength: 9,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: '771234567',
                          counterText: '',
                        ),
                      ),
                    ),
                  ],
                ),

                // ✅ PHONE WARNING
                if (_phoneController.text.length == 9 &&
                    _isRepeatingDigits(_phoneController.text)) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Please enter a valid phone number',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // ======================
                // EMAIL
                // ======================
                _buildInput(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  nextFocus: _passwordFocus,
                  hint: 'Email address',
                  icon: Icons.email_outlined,
                  inputBg: inputBg,
                  textColor: textColor,
                ),

                const SizedBox(height: 12),

                // ======================
                // PASSWORD
                // ======================
                Container(
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Strong password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),

                // ✅ PASSWORD STRENGTH INDICATOR
                if (_passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildPasswordStrength(),
                ],

                const SizedBox(height: 24),

                // ======================
                // CREATE BUTTON
                // ======================
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _canSubmit ? _createAccount : null,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Create Account'),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ✅ PASSWORD STRENGTH UI
  // ============================================================
  Widget _buildPasswordStrength() {
    final password = _passwordController.text;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRequirement('At least 8 characters', password.length >= 8),
          _buildRequirement(
            'Uppercase letter',
            password.contains(RegExp(r'[A-Z]')),
          ),
          _buildRequirement(
            'Lowercase letter',
            password.contains(RegExp(r'[a-z]')),
          ),
          _buildRequirement('Number', password.contains(RegExp(r'[0-9]'))),
          _buildRequirement(
            'Special character',
            password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirement(String text, bool met) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle : Icons.circle_outlined,
          size: 16,
          color: met ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: met ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    required String hint,
    required IconData icon,
    required Color inputBg,
    required Color textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onSubmitted: (_) {
          if (nextFocus != null) {
            FocusScope.of(context).requestFocus(nextFocus);
          }
        },
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        style: TextStyle(color: textColor),
      ),
    );
  }
}
