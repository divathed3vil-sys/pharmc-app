import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants.dart';
import '../../services/auth_service.dart';
import '../main_navigation.dart';

class JoinSharedAccountScreen extends StatefulWidget {
  const JoinSharedAccountScreen({super.key});

  @override
  State<JoinSharedAccountScreen> createState() =>
      _JoinSharedAccountScreenState();
}

class _JoinSharedAccountScreenState extends State<JoinSharedAccountScreen>
    with SingleTickerProviderStateMixin {
  // ── 6 individual controllers for each digit ──
  final List<TextEditingController> _digitControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isJoining = false;
  String? _errorMessage;
  bool _showDeviceLimit = false;

  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  String get _shareCode => _digitControllers.map((c) => c.text).join();

  bool get _canJoin {
    final code = _shareCode;
    return code.length == 6 && RegExp(r'^\d{6}$').hasMatch(code) && !_isJoining;
  }

  @override
  void initState() {
    super.initState();

    for (final c in _digitControllers) {
      c.addListener(
        () => setState(() {
          _errorMessage = null;
          _showDeviceLimit = false;
        }),
      );
    }

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
    for (final c in _digitControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
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

  // ============ JOIN LOGIC ============

  Future<void> _joinSharedAccount() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isJoining = true;
      _errorMessage = null;
      _showDeviceLimit = false;
    });

    final result = await AuthService.joinSharedAccount(shareCode: _shareCode);

    if (!mounted) return;
    setState(() => _isJoining = false);

    if (result.success) {
      Navigator.pushAndRemoveUntil(
        context,
        _smoothRoute(const MainNavigation()),
        (route) => false,
      );
    } else if (result.needsApproval) {
      setState(() => _showDeviceLimit = true);
    } else {
      setState(() => _errorMessage = result.message);
    }
  }

  // ============ BUILD ============

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
                // ── Background blur blobs ──
                Positioned(
                  top: -100,
                  right: -120,
                  child: _blurBlob(
                    color: Colors.purple.withOpacity(isDark ? 0.20 : 0.14),
                    size: 240,
                  ),
                ),
                Positioned(
                  bottom: -130,
                  left: -100,
                  child: _blurBlob(
                    color: Colors.teal.withOpacity(isDark ? 0.16 : 0.12),
                    size: 240,
                  ),
                ),

                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Brand ──
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

                      // ── Main glass card ──
                      _glassCard(
                        isDark: isDark,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Icon + Title ──
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.purple.shade400,
                                        Colors.purple.shade700,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.purple.withOpacity(
                                          isDark ? 0.3 : 0.2,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.group_add_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Join shared account',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: text,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Enter the 6-digit code shared by the account owner.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: sub,
                                          fontWeight: FontWeight.w600,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 22),

                            // ── 6-digit input boxes ──
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(6, (index) {
                                  return _digitInput(
                                    isDark: isDark,
                                    text: text,
                                    sub: sub,
                                    index: index,
                                  );
                                }),
                              ),
                            ),

                            const SizedBox(height: 18),

                            // ── Info card ──
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(
                                  isDark ? 0.10 : 0.05,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.purple.withOpacity(0.18),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    color: Colors.purple.shade400,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Ask the account owner to generate a share code '
                                      'from Settings → Share Account. '
                                      'Each code is one-time use. Maximum 4 devices per account.',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.purple.shade200
                                            : Colors.purple.shade800,
                                        fontSize: 11,
                                        height: 1.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ── Error message ──
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 14),
                              _errorBox(isDark, _errorMessage!),
                            ],

                            // ── Device limit card ──
                            if (_showDeviceLimit) ...[
                              const SizedBox(height: 14),
                              _deviceLimitCard(isDark),
                            ],

                            const SizedBox(height: 18),

                            // ── Join button ──
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _canJoin ? _joinSharedAccount : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple.shade600,
                                  disabledBackgroundColor: isDark
                                      ? Colors.white.withOpacity(0.10)
                                      : Colors.grey.shade200,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: _isJoining
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Icon(Icons.login_rounded, size: 20),
                                          SizedBox(width: 8),
                                          Text(
                                            'Join Account',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Back link ──
                      Center(
                        child: GestureDetector(
                          onTap: _isJoining
                              ? null
                              : () => Navigator.pop(context),
                          child: RichText(
                            text: TextSpan(
                              text: 'Go back to ',
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

  // ============ DIGIT INPUT BOX ============

  Widget _digitInput({
    required bool isDark,
    required Color text,
    required Color sub,
    required int index,
  }) {
    final hasValue = _digitControllers[index].text.isNotEmpty;
    final isFocused = _focusNodes[index].hasFocus;

    return Container(
      width: 46,
      height: 56,
      margin: EdgeInsets.only(
        left: index == 0 ? 0 : 4,
        right: index == 5 ? 0 : 4,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(hasValue ? 0.10 : 0.06)
            : Colors.black.withOpacity(hasValue ? 0.05 : 0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFocused
              ? Colors.purple.shade400
              : hasValue
              ? Colors.purple.shade400.withOpacity(0.4)
              : isDark
              ? Colors.white.withOpacity(0.12)
              : Colors.black.withOpacity(0.08),
          width: isFocused ? 2 : 1.5,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: _digitControllers[index],
        focusNode: _focusNodes[index],
        maxLength: 1,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
          color: text,
          fontWeight: FontWeight.w900,
          fontSize: 22,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            // Move to next field
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            // Move to previous field on backspace
            _focusNodes[index - 1].requestFocus();
          }
          setState(() {});
        },
      ),
    );
  }

  // ============ DEVICE LIMIT CARD ============

  Widget _deviceLimitCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.devices_rounded,
                  color: Colors.orange.shade500,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Device limit reached',
                style: TextStyle(
                  color: Colors.orange.shade600,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'This account already has the maximum of 4 devices connected. '
            'To add this device, the account owner needs to:',
            style: TextStyle(
              color: isDark ? Colors.orange.shade200 : Colors.orange.shade800,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          _limitStep(
            isDark,
            '1',
            'Open Settings → Security → Log out a device',
          ),
          _limitStep(isDark, '2', 'Generate a new share code'),
          _limitStep(isDark, '3', 'Share the new code with you'),
        ],
      ),
    );
  }

  Widget _limitStep(bool isDark, String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                num,
                style: TextStyle(
                  color: Colors.orange.shade500,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isDark ? Colors.orange.shade200 : Colors.orange.shade800,
                fontSize: 11,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
          padding: const EdgeInsets.all(20),
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
