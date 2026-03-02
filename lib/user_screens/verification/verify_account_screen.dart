import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/verification_service.dart';
import '../../services/preferences_service.dart';
import '../main_navigation.dart';

class VerifyAccountScreen extends StatefulWidget {
  const VerifyAccountScreen({super.key});

  @override
  State<VerifyAccountScreen> createState() => _VerifyAccountScreenState();
}

class _VerifyAccountScreenState extends State<VerifyAccountScreen>
    with SingleTickerProviderStateMixin {
  // ---- State ----
  bool _loading = false;
  String? _error;
  VerificationState? _verState;

  // Code input controllers (6 digits)
  final List<TextEditingController> _codeControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _codeFocusNodes = List.generate(6, (_) => FocusNode());

  // Lock countdown
  Timer? _lockTimer;
  int _lockSecondsRemaining = 0;

  // Polling for admin code_sent toggle
  Timer? _pollTimer;

  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  // ---- Computed ----
  String get _enteredCode => _codeControllers.map((c) => c.text).join();

  bool get _codeComplete => _enteredCode.length == 6;

  bool get _canSubmitCode => _codeComplete && !_loading && !_isLocked;

  bool get _isLocked => _lockSecondsRemaining > 0;

  bool get _hasRequestedCode =>
      _verState != null &&
      (_verState!.status == 'pending' || _verState!.status == 'approved');

  bool get _codeSentByAdmin => _verState?.codeSent == true;

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

    _loadState();
  }

  @override
  void dispose() {
    _anim.dispose();
    _lockTimer?.cancel();
    _pollTimer?.cancel();
    for (final c in _codeControllers) {
      c.dispose();
    }
    for (final f in _codeFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // ---- Load verification state from server ----
  Future<void> _loadState() async {
    setState(() => _loading = true);
    try {
      final state = await VerificationService.getVerificationState();
      if (!mounted) return;
      setState(() {
        _verState = state;
        _loading = false;
        _error = null;
      });

      // Start lock countdown if locked
      if (state.isLocked && state.lockRemainingSeconds > 0) {
        _startLockCountdown(state.lockRemainingSeconds);
      }

      // Start polling if waiting for admin to send code
      if (state.status == 'pending' && !state.codeSent) {
        _startPolling();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load verification status.';
      });
    }
  }

  // ---- Request verification (Step 1) ----
  Future<void> _requestVerification() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await VerificationService.requestVerification();

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      // Reload state to show "waiting for admin" UI
      await _loadState();
    } else {
      setState(() => _error = result.message);
    }
  }

  // ---- Submit verification code (Step 3) ----
  Future<void> _submitCode() async {
    if (!_canSubmitCode) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await VerificationService.submitVerificationCode(
      enteredCode: _enteredCode,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      // Navigate to success screen
      _pollTimer?.cancel();
      _lockTimer?.cancel();
      Navigator.pushReplacement(
        context,
        _smoothRoute(const _VerificationSuccessScreen()),
      );
    } else if (result.codePending) {
      setState(() => _error = result.message);
    } else if (result.isLocked) {
      _startLockCountdown(result.lockRemainingMinutes * 60);
      setState(() => _error = result.message);
      _clearCodeFields();
    } else {
      setState(() => _error = result.message);
      _clearCodeFields();
    }
  }

  // ---- Lock countdown ----
  void _startLockCountdown(int seconds) {
    _lockTimer?.cancel();
    setState(() => _lockSecondsRemaining = seconds);
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _lockSecondsRemaining--;
        if (_lockSecondsRemaining <= 0) {
          _lockSecondsRemaining = 0;
          timer.cancel();
          _loadState(); // Refresh state after unlock
        }
      });
    });
  }

  // ---- Polling for admin code_sent ----
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!mounted) return;
      try {
        final state = await VerificationService.getVerificationState();
        if (!mounted) return;
        setState(() => _verState = state);
        if (state.codeSent) {
          _pollTimer?.cancel();
        }
      } catch (_) {}
    });
  }

  // ---- Clear code fields ----
  void _clearCodeFields() {
    for (final c in _codeControllers) {
      c.clear();
    }
    if (_codeFocusNodes.isNotEmpty) {
      _codeFocusNodes[0].requestFocus();
    }
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
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                ),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
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
          'Verify Account',
          style: TextStyle(color: text, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- Main Card ----
                  _glassCard(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unlock ordering',
                          style: TextStyle(
                            color: text,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Verification helps us prevent fake orders and protect pharmacies.',
                          style: TextStyle(color: sub, height: 1.4),
                        ),
                        const SizedBox(height: 20),

                        // ---- STEP 1: Request Verification ----
                        if (!_hasRequestedCode) ...[
                          _sectionTitle(
                            '1) Request verification code',
                            text,
                            sub,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the button below to request a verification code. '
                            'An admin will send you a 6-digit code.',
                            style: TextStyle(
                              color: sub,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _requestVerification,
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
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Request verification',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                      ),
                                    ),
                            ),
                          ),
                        ],

                        // ---- STEP 2: Waiting for admin ----
                        if (_hasRequestedCode && !_codeSentByAdmin) ...[
                          _sectionTitle('Waiting for admin', text, sub),
                          const SizedBox(height: 12),
                          _waitingForAdminCard(isDark, text, sub),
                        ],

                        // ---- STEP 3: Enter code ----
                        if (_hasRequestedCode && _codeSentByAdmin) ...[
                          _sectionTitle('Enter verification code', text, sub),
                          const SizedBox(height: 12),

                          // Lock countdown
                          if (_isLocked) ...[
                            _lockCountdownCard(isDark),
                            const SizedBox(height: 12),
                          ],

                          // 6-digit code input
                          _codeInputRow(isDark, text, sub),
                          const SizedBox(height: 6),

                          // Attempts remaining
                          if (_verState != null && !_isLocked)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: _attemptsIndicator(isDark),
                            ),

                          const SizedBox(height: 16),

                          // Submit button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _canSubmitCode ? _submitCode : null,
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
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Verify',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                      ),
                                    ),
                            ),
                          ),
                        ],

                        // ---- Error ----
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          _errorCard(isDark, _error!),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============ WIDGETS ============

  Widget _sectionTitle(String t, Color text, Color sub) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.14),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Icon(
              Icons.verified_rounded,
              size: 14,
              color: Colors.teal.shade400,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            t,
            style: TextStyle(
              color: text,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _waitingForAdminCard(bool isDark, Color text, Color sub) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.22)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.hourglass_top_rounded,
            color: Colors.orange.shade500,
            size: 36,
          ),
          const SizedBox(height: 10),
          Text(
            'Code not sent yet',
            style: TextStyle(
              color: Colors.orange.shade600,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'An admin will review your request and send you a 6-digit code. '
            'This page auto-refreshes every 10 seconds.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.orange.shade200 : Colors.orange.shade800,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.orange.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _codeInputRow(bool isDark, Color text, Color sub) {
    final inputBg = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.03);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.10)
        : Colors.black.withOpacity(0.06);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 48,
          height: 56,
          child: Container(
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _codeFocusNodes[index].hasFocus
                    ? Colors.teal.shade400
                    : borderColor,
                width: _codeFocusNodes[index].hasFocus ? 2 : 1,
              ),
            ),
            child: TextField(
              controller: _codeControllers[index],
              focusNode: _codeFocusNodes[index],
              enabled: !_isLocked && !_loading,
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
                  _codeFocusNodes[index + 1].requestFocus();
                } else if (value.isEmpty && index > 0) {
                  _codeFocusNodes[index - 1].requestFocus();
                }
                setState(() {});
              },
            ),
          ),
        );
      }),
    );
  }

  Widget _attemptsIndicator(bool isDark) {
    final attempts = _verState?.attempts ?? 0;
    final remaining = (5 - attempts).clamp(0, 5);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(5, (i) {
          final used = i < attempts;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: used
                    ? Colors.red.shade400
                    : Colors.teal.shade400.withOpacity(0.3),
              ),
            ),
          );
        }),
        const SizedBox(width: 8),
        Text(
          '$remaining/5 attempts left',
          style: TextStyle(
            color: remaining <= 2
                ? Colors.red.shade400
                : (isDark ? Colors.grey.shade500 : Colors.grey.shade600),
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _lockCountdownCard(bool isDark) {
    final minutes = _lockSecondsRemaining ~/ 60;
    final seconds = _lockSecondsRemaining % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Icon(Icons.lock_clock_rounded, color: Colors.red.shade400, size: 32),
          const SizedBox(height: 8),
          Text(
            'Account locked',
            style: TextStyle(
              color: Colors.red.shade400,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Too many incorrect attempts.',
            style: TextStyle(
              color: isDark ? Colors.red.shade200 : Colors.red.shade700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            timeStr,
            style: TextStyle(
              color: Colors.red.shade400,
              fontWeight: FontWeight.w900,
              fontSize: 28,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'until unlock',
            style: TextStyle(
              color: isDark ? Colors.red.shade300 : Colors.red.shade600,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard(bool isDark, String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.25)),
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
                fontSize: 13,
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

// ============================================================
// Success Screen — shown after successful verification
// ============================================================
class _VerificationSuccessScreen extends StatefulWidget {
  const _VerificationSuccessScreen();

  @override
  State<_VerificationSuccessScreen> createState() =>
      _VerificationSuccessScreenState();
}

class _VerificationSuccessScreenState extends State<_VerificationSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scale = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.elasticOut));
    _fade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));

    _anim.forward();

    // Auto-redirect to home after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainNavigation(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
        (route) => false,
      );
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA);
    final text = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade700],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 24,
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 52,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Verified!',
                  style: TextStyle(
                    color: text,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your account has been verified.\nYou can now place real orders.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: sub, height: 1.5),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.teal.shade400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Redirecting to home...',
                  style: TextStyle(
                    color: sub,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Pending Screen (kept for backward compatibility)
// ============================================================
class VerificationPendingScreen extends StatelessWidget {
  const VerificationPendingScreen({super.key});

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
        automaticallyImplyLeading: false,
        title: Text(
          'Verification',
          style: TextStyle(color: text, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.hourglass_top_rounded,
                      color: Colors.orange.shade500,
                      size: 52,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Request submitted',
                      style: TextStyle(
                        color: text,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We will send you a verification code soon.\n'
                      'Until then, you can prepare demo orders.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: sub, height: 1.45),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade600,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Back',
                          style: TextStyle(fontWeight: FontWeight.w900),
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
}
