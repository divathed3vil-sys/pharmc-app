import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/draft_order_service.dart';

class LocalAddAddressScreen extends StatefulWidget {
  const LocalAddAddressScreen({super.key});

  @override
  State<LocalAddAddressScreen> createState() => _LocalAddAddressScreenState();
}

class _LocalAddAddressScreenState extends State<LocalAddAddressScreen>
    with SingleTickerProviderStateMixin {
  final _addressController = TextEditingController();
  final _labelController = TextEditingController(text: 'Home');

  bool _saving = false;

  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool get _canSave => !_saving && _addressController.text.trim().length >= 6;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));

    _anim.forward();
    _addressController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _anim.dispose();
    _addressController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      // NOTE: no GPS for unverified users, keep 0,0 or null-like values.
      // If you prefer, store Colombo as default. I used 0,0 intentionally.
      final addr = DraftAddress(
        label: _labelController.text.trim().isEmpty
            ? 'Home'
            : _labelController.text.trim(),
        addressLine: _addressController.text.trim(),
        latitude: 0,
        longitude: 0,
      );
      await DraftOrderService.saveDraftAddress(addr);

      if (!mounted) return;
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
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
        title: Text(
          'Add Address',
          style: TextStyle(color: text, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _glassCard(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Local address (Draft)',
                      style: TextStyle(
                        color: text,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'This address will be saved on your device until your account is verified.',
                      style: TextStyle(color: sub, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 18),

                    _labelField(isDark, text, sub),
                    const SizedBox(height: 12),
                    _addressField(isDark, text, sub),

                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _canSave ? _save : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade600,
                          disabledBackgroundColor: isDark
                              ? Colors.white.withOpacity(0.10)
                              : Colors.grey.shade200,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
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
                                'Save Address',
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
        ),
      ),
    );
  }

  Widget _labelField(bool isDark, Color text, Color sub) {
    final inputBg = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.03);

    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _labelController,
        style: TextStyle(color: text, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          hintText: 'Label (Home / Work)',
          hintStyle: TextStyle(color: sub),
          prefixIcon: Icon(Icons.label_rounded, color: sub),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _addressField(bool isDark, Color text, Color sub) {
    final inputBg = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.03);

    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _addressController,
        maxLines: 3,
        style: TextStyle(color: text),
        decoration: InputDecoration(
          hintText: 'Enter your address (street, town, landmarks...)',
          hintStyle: TextStyle(color: sub),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Icon(Icons.location_on_rounded, color: sub),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
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
          height: double.infinity,
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
