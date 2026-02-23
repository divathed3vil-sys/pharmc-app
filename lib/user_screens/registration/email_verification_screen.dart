import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants.dart';
import '../../services/auth_service.dart';
import 'language_selection_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;
  bool _verified = false;

  late AnimationController _animController;
  late Animation<double> _fadeIn;

  String get _otpCode => _controllers.map((c) => c.text).join();

  bool get _isComplete => _otpCode.length == 6;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    // Auto-verify when all 6 digits entered
    for (var controller in _controllers) {
      controller.addListener(() {
        setState(() {
          _errorMessage = null;
        });
        if (_isComplete && !_isVerifying) {
          _verify();
        }
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      // Move to next box
      _focusNodes[index + 1].requestFocus();
    }
  }

  void _onKeyPress(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      // Move to previous box on backspace
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _handlePaste(String pastedText) {
    final digits = pastedText.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 6) {
      for (int i = 0; i < 6; i++) {
        _controllers[i].text = digits[i];
      }
      _focusNodes[5].requestFocus();
    }
  }

  void _clearAll() {
    for (var c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
    setState(() {
      _errorMessage = null;
    });
  }

  Future<void> _verify() async {
    if (!_isComplete) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final result = await AuthService.verifyOTP(
      email: widget.email,
      otp: _otpCode,
    );

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _verified = true;
        _isVerifying = false;
      });

      // Brief success animation then navigate
      await Future.delayed(const Duration(milliseconds: 1200));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
        );
      }
    } else {
      setState(() {
        _isVerifying = false;
        _errorMessage = result.message;
      });
      _clearAll();
    }
  }

  Future<void> _resend() async {
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    final result = await AuthService.resendOTP(widget.email);

    if (!mounted) return;

    setState(() {
      _isResending = false;
    });

    _clearAll();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success
            ? Colors.teal.shade600
            : Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);
    final backBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);

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
      body: FadeTransition(
        opacity: _fadeIn,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Header
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

                // Title with animated check
                Row(
                  children: [
                    Text(
                      _verified ? 'Verified!' : 'Check your email',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: _verified ? Colors.green.shade600 : textColor,
                      ),
                    ),
                    if (_verified) ...[
                      const SizedBox(width: 10),
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green.shade600,
                        size: 28,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),

                // Subtitle
                Text(
                  _verified
                      ? 'Your email has been verified successfully.'
                      : 'Enter the 6-digit code we sent to:',
                  style: TextStyle(fontSize: 15, color: subtextColor),
                ),

                if (!_verified) ...[
                  const SizedBox(height: 8),
                  // Email display
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 18,
                          color: Colors.teal.shade600,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.email,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // 6-digit OTP boxes
                  _buildOTPBoxes(isDark, textColor),

                  // Error message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.red.shade900.withOpacity(0.3)
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.red.shade800
                              : Colors.red.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: Colors.red.shade400,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.red.shade300
                                    : Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Verifying indicator
                  if (_isVerifying)
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.teal.shade600,
                              strokeWidth: 2.5,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Verifying...',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.teal.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],

                const Spacer(),

                // Resend section
                if (!_verified)
                  Center(
                    child: Column(
                      children: [
                        Text(
                          "Didn't receive the code?",
                          style: TextStyle(fontSize: 14, color: subtextColor),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _isResending ? null : _resend,
                          child: _isResending
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.teal.shade600,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Resend Code',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.teal.shade600,
                                  ),
                                ),
                        ),
                      ],
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

  Widget _buildOTPBoxes(bool isDark, Color textColor) {
    final boxBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);
    final activeBorder = Colors.teal.shade600;
    final inactiveBorder = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final filledBorder = isDark ? Colors.teal.shade700 : Colors.teal.shade300;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        final hasValue = _controllers[index].text.isNotEmpty;

        return SizedBox(
          width: 48,
          height: 58,
          child: RawKeyboardListener(
            focusNode: FocusNode(),
            onKey: (event) => _onKeyPress(index, event),
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              enabled: !_isVerifying && !_verified,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: boxBg,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: inactiveBorder, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: hasValue ? filledBorder : inactiveBorder,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: activeBorder, width: 2),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: _verified ? Colors.green.shade400 : inactiveBorder,
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (value) {
                if (value.length == 1) {
                  _onDigitChanged(index, value);
                }
                // Handle paste
                if (value.length > 1) {
                  _handlePaste(value);
                }
              },
            ),
          ),
        );
      }),
    );
  }
}
