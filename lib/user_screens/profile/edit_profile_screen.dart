import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/preferences_service.dart';
import '../../services/auth_service.dart';
import '../../services/verification_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String _email = '';

  bool _hasChanges = false;
  bool _saving = false;
  String? _error;

  // ── Verification status ──
  bool _statusLoading = true;
  String _verificationStatus = 'unverified';

  bool get _phoneLocked =>
      _verificationStatus == 'pending' || _verificationStatus == 'approved';

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _nameController.text = PreferencesService.getUserName() ?? '';
    final age = PreferencesService.getUserAge() ?? 0;
    _ageController.text = age == 0 ? '' : age.toString();
    _phoneController.text = PreferencesService.getUserPhone() ?? '';
    _email = PreferencesService.getUserEmail() ?? '';

    _nameController.addListener(_onChange);
    _ageController.addListener(_onChange);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _statusLoading = true);

    final s = await VerificationService.getMyVerificationStatus();
    if (!mounted) return;

    setState(() {
      _verificationStatus = s;
      _statusLoading = false;
    });

    // Only listen to phone edits if it's not locked
    _phoneController.removeListener(_onChange);
    if (!_phoneLocked) {
      _phoneController.addListener(_onChange);
    }
  }

  void _onChange() {
    setState(() {
      _hasChanges = true;
      _error = null;
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool _isValidPhone(String p) => RegExp(r'^\d{9}$').hasMatch(p);

  Future<void> _save() async {
    if (_saving) return;

    final fullName = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim());
    final phone = _phoneController.text.trim();

    if (fullName.length < 2) {
      setState(() => _error = 'Please enter your full name.');
      return;
    }
    if (_ageController.text.trim().isNotEmpty &&
        (age == null || age < 10 || age > 120)) {
      setState(() => _error = 'Please enter a valid age.');
      return;
    }
    if (!_phoneLocked && phone.isNotEmpty && !_isValidPhone(phone)) {
      setState(() => _error = 'Phone number must be 9 digits.');
      return;
    }

    setState(() => _saving = true);

    try {
      await AuthService.updateProfile(
        fullName: fullName,
        age: age,
        phone: _phoneLocked ? null : (phone.isEmpty ? null : phone),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated'),
          backgroundColor: Colors.teal.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'Failed to save changes. Try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(color: text, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh status',
            onPressed: _loadStatus,
            icon: Icon(Icons.refresh_rounded, color: sub),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
            child: Column(
              children: [
                // ── Profile picture placeholder ──
                _glassCard(
                  isDark: isDark,
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(isDark ? 0.18 : 0.12),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.teal.withOpacity(0.22),
                          ),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: Colors.teal.shade400,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Profile picture',
                              style: TextStyle(
                                color: text,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Coming soon',
                              style: TextStyle(color: sub, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          'Soon',
                          style: TextStyle(
                            color: Colors.orange.shade600,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Fields card ──
                _glassCard(
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _field(
                        isDark: isDark,
                        text: text,
                        sub: sub,
                        controller: _nameController,
                        icon: Icons.person_outline_rounded,
                        hint: 'Full name',
                        keyboardType: TextInputType.name,
                      ),
                      const SizedBox(height: 10),
                      _field(
                        isDark: isDark,
                        text: text,
                        sub: sub,
                        controller: _ageController,
                        icon: Icons.cake_outlined,
                        hint: 'Age',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 10),
                      _phoneField(isDark, text, sub),

                      // ── Phone locked notice ──
                      if (_phoneLocked || _statusLoading) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (_statusLoading)
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.orange.shade400,
                                ),
                              )
                            else
                              Icon(
                                Icons.lock_rounded,
                                size: 14,
                                color: Colors.orange.shade400,
                              ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _statusLoading
                                    ? 'Checking verification status...'
                                    : 'Phone number is locked while verification is pending/approved.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade400,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 10),

                      // ── Email read-only ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.black.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.10)
                                : Colors.black.withOpacity(0.06),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.email_outlined, color: sub),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _email.isEmpty ? 'No email' : _email,
                                style: TextStyle(
                                  color: text,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                'Read only',
                                style: TextStyle(
                                  color: sub,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Error message ──
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  _glassCard(
                    isDark: isDark,
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Colors.red.shade300,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Save button ──
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: (!_hasChanges || _saving) ? null : _save,
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
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save changes',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required bool isDark,
    required Color text,
    required Color sub,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required TextInputType keyboardType,
  }) {
    final inputBg = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.03);

    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.10)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: text, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: sub),
          prefixIcon: Icon(icon, color: sub),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _phoneField(bool isDark, Color text, Color sub) {
    final inputBg = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.03);

    final lockedBg = isDark
        ? Colors.white.withOpacity(0.03)
        : Colors.black.withOpacity(0.02);

    return Opacity(
      opacity: _phoneLocked ? 0.55 : 1.0,
      child: Row(
        children: [
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: _phoneLocked ? lockedBg : inputBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.10)
                    : Colors.black.withOpacity(0.06),
              ),
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
                color: _phoneLocked ? lockedBg : inputBg,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.10)
                      : Colors.black.withOpacity(0.06),
                ),
              ),
              child: TextField(
                controller: _phoneController,
                maxLength: 9,
                enabled: !_phoneLocked,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: text, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: _phoneLocked ? 'Locked' : '771234567',
                  hintStyle: TextStyle(color: sub),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                  suffixIcon: _phoneLocked
                      ? Icon(
                          Icons.lock_rounded,
                          size: 18,
                          color: Colors.orange.shade400,
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard({required bool isDark, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(22),
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
}
