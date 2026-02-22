import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/preferences_service.dart';
import 'phone_screen.dart';

class NameAgeScreen extends StatefulWidget {
  const NameAgeScreen({super.key});

  @override
  State<NameAgeScreen> createState() => _NameAgeScreenState();
}

class _NameAgeScreenState extends State<NameAgeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  bool get _canContinue =>
      _nameController.text.trim().length >= 2 &&
      _ageController.text.trim().isNotEmpty &&
      (int.tryParse(_ageController.text.trim()) ?? 0) >= 10 &&
      (int.tryParse(_ageController.text.trim()) ?? 0) <= 120;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    _ageController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _continue() async {
    await PreferencesService.setUserName(_nameController.text.trim());
    await PreferencesService.setUserAge(int.parse(_ageController.text.trim()));
    await PreferencesService.setUserRole('customer');

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PhoneScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final Color subtextColor = isDark
        ? Colors.grey.shade400
        : Colors.grey.shade500;
    final Color inputBg = isDark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFF5F5F5);
    final Color backBg = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFF5F5F5);
    final Color hintColor = isDark
        ? Colors.grey.shade600
        : Colors.grey.shade400;
    final Color iconColor = isDark
        ? Colors.grey.shade400
        : Colors.grey.shade500;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: backBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back_rounded, color: textColor, size: 20),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildProgress(1, 3, isDark),
              const SizedBox(height: 32),
              Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.teal.shade700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "What's your name?",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We use this to personalize your experience.',
                style: TextStyle(fontSize: 15, color: subtextColor),
              ),
              const SizedBox(height: 32),
              _buildInputField(
                controller: _nameController,
                hint: 'Full Name',
                icon: Icons.person_outline_rounded,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                inputBg: inputBg,
                hintColor: hintColor,
                iconColor: iconColor,
                textColor: textColor,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _ageController,
                hint: 'Age',
                icon: Icons.cake_outlined,
                keyboardType: TextInputType.number,
                inputBg: inputBg,
                hintColor: hintColor,
                iconColor: iconColor,
                textColor: textColor,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _canContinue ? _continue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                    disabledBackgroundColor: isDark
                        ? Colors.teal.shade900
                        : Colors.teal.shade100,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white60,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color inputBg,
    required Color hintColor,
    required Color iconColor,
    required Color textColor,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: hintColor, fontWeight: FontWeight.w400),
          prefixIcon: Icon(icon, color: iconColor, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(int current, int total, bool isDark) {
    return Row(
      children: List.generate(total, (index) {
        final isActive = index < current;
        final isCurrent = index == current - 1;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index < total - 1 ? 8 : 0),
            decoration: BoxDecoration(
              color: isActive
                  ? (isCurrent ? Colors.teal.shade600 : Colors.teal.shade200)
                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
