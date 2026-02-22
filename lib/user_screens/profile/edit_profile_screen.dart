import 'package:flutter/material.dart';
import '../../services/preferences_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = PreferencesService.getUserName() ?? '';
    _ageController.text = (PreferencesService.getUserAge() ?? '').toString();
    if (_ageController.text == '0') _ageController.text = '';
    _phoneController.text = PreferencesService.getUserPhone() ?? '';
    _emailController.text = PreferencesService.getUserEmail() ?? '';

    _nameController.addListener(_onChange);
    _ageController.addListener(_onChange);
    _phoneController.addListener(_onChange);
    _emailController.addListener(_onChange);
  }

  void _onChange() {
    setState(() {
      _hasChanges = true;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_nameController.text.trim().length >= 2) {
      await PreferencesService.setUserName(_nameController.text.trim());
    }
    final age = int.tryParse(_ageController.text.trim());
    if (age != null && age >= 10 && age <= 120) {
      await PreferencesService.setUserAge(age);
    }
    if (_phoneController.text.trim().length == 9) {
      await PreferencesService.setUserPhone(_phoneController.text.trim());
    }
    if (_emailController.text.trim().isNotEmpty) {
      await PreferencesService.setUserEmail(_emailController.text.trim());
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated'),
          backgroundColor: Colors.teal.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    // ignore: unused_local_variable
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
    final Color labelColor = isDark
        ? Colors.grey.shade400
        : Colors.grey.shade600;
    final Color prefixColor = isDark
        ? Colors.grey.shade400
        : Colors.grey.shade600;

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
        title: Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            _buildLabel('Full Name', labelColor),
            const SizedBox(height: 8),
            _buildField(
              controller: _nameController,
              hint: 'Your full name',
              icon: Icons.person_outline_rounded,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              inputBg: inputBg,
              hintColor: hintColor,
              iconColor: iconColor,
              textColor: textColor,
            ),
            const SizedBox(height: 20),
            _buildLabel('Age', labelColor),
            const SizedBox(height: 8),
            _buildField(
              controller: _ageController,
              hint: 'Your age',
              icon: Icons.cake_outlined,
              keyboardType: TextInputType.number,
              inputBg: inputBg,
              hintColor: hintColor,
              iconColor: iconColor,
              textColor: textColor,
            ),
            const SizedBox(height: 20),
            _buildLabel('Phone Number', labelColor),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.0,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  hintText: '7X XXX XXXX',
                  hintStyle: TextStyle(
                    color: hintColor,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8),
                    child: Text(
                      '+94',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: prefixColor,
                      ),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildLabel('Email Address', labelColor),
            const SizedBox(height: 8),
            _buildField(
              controller: _emailController,
              hint: 'your@email.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              inputBg: inputBg,
              hintColor: hintColor,
              iconColor: iconColor,
              textColor: textColor,
            ),
            const SizedBox(height: 40),
            // Save button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _hasChanges ? _save : null,
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
                  'Save Changes',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
    );
  }

  Widget _buildField({
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
}
