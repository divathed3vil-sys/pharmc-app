import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'preferences_service.dart';

class VerificationService {
  static final _client = Supabase.instance.client;

  // ============ STATUS QUERIES ============

  /// Returns the verification status of the current user from the `users` table.
  /// Falls back to 'unverified' if no user is logged in or status is missing.
  static Future<String> getMyVerificationStatus() async {
    final userId = PreferencesService.getUserId();
    if (userId == null || userId.isEmpty) return 'unverified';

    final data = await _client
        .from('users')
        .select('verification_status')
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return 'unverified';
    return (data['verification_status'] ?? 'unverified').toString();
  }

  /// Returns true if the current user's verification status is 'approved'.
  static Future<bool> isApproved() async {
    return (await getMyVerificationStatus()) == 'approved';
  }

  // ============ FULL VERIFICATION STATE ============

  /// Returns the complete verification state for the current user.
  /// Includes: verification_status, verification_code_sent (boolean),
  /// verification_attempts, verification_blocked_until, and computed lock status.
  ///
  /// Lock logic relies solely on verification_blocked_until > now (not attempts >= 5).
  static Future<VerificationState> getVerificationState() async {
    final userId = PreferencesService.getUserId();
    if (userId == null || userId.isEmpty) {
      return VerificationState(
        status: 'unverified',
        codeSent: false,
        attempts: 0,
        blockedUntil: null,
        isLocked: false,
        lockRemainingSeconds: 0,
      );
    }

    final data = await _client
        .from('users')
        .select(
          'verification_status, '
          'verification_code_sent, '
          'verification_attempts, '
          'verification_blocked_until',
        )
        .eq('id', userId)
        .maybeSingle();

    if (data == null) {
      return VerificationState(
        status: 'unverified',
        codeSent: false,
        attempts: 0,
        blockedUntil: null,
        isLocked: false,
        lockRemainingSeconds: 0,
      );
    }

    final status = (data['verification_status'] ?? 'unverified').toString();
    final codeSent = data['verification_code_sent'] == true;
    final attempts = (data['verification_attempts'] ?? 0) as int;
    final blockedUntilStr = data['verification_blocked_until']?.toString();

    DateTime? blockedUntil;
    if (blockedUntilStr != null && blockedUntilStr.isNotEmpty) {
      blockedUntil = DateTime.tryParse(blockedUntilStr);
    }

    // Compute lock status: rely solely on verification_blocked_until > now
    bool isLocked = false;
    int lockRemainingSeconds = 0;

    if (blockedUntil != null) {
      final now = DateTime.now().toUtc();
      if (blockedUntil.isAfter(now)) {
        isLocked = true;
        lockRemainingSeconds = blockedUntil.difference(now).inSeconds;
      }
    }

    return VerificationState(
      status: status,
      codeSent: codeSent,
      attempts: attempts,
      blockedUntil: blockedUntil,
      isLocked: isLocked,
      lockRemainingSeconds: lockRemainingSeconds,
    );
  }

  /// Returns true if the user is currently locked out from verification attempts.
  /// Lock is determined solely by verification_blocked_until > now.
  static Future<bool> isVerificationLocked() async {
    final state = await getVerificationState();
    return state.isLocked;
  }

  // ============ REQUEST VERIFICATION ============

  /// Generates a 6-digit verification code, hashes it with SHA-256,
  /// stores the hash in users.verification_code_hash,
  /// resets verification_attempts to 0,
  /// sets verification_code_sent to false (admin must toggle to true),
  /// and returns the plain-text code (so admin can see it / send it).
  ///
  /// Flow:
  ///   1. Generate random 6-digit code.
  ///   2. Hash with SHA-256.
  ///   3. Update users row:
  ///      - verification_code_hash = SHA-256(code)
  ///      - verification_attempts = 0
  ///      - verification_code_sent = false
  ///      - verification_blocked_until = null
  ///      - verification_status = 'pending' (request submitted)
  ///   4. Return plain-text code in result.
  static Future<VerificationResult> requestVerification() async {
    try {
      final userId = PreferencesService.getUserId();
      if (userId == null || userId.isEmpty) {
        return VerificationResult(
          success: false,
          message: 'Please log in again.',
        );
      }

      // Step 1: Generate 6-digit code
      final code = _generateCode();

      // Step 2: Hash with SHA-256
      final codeHash = _hashCode(code);

      // Step 3: Update users table
      await _client
          .from('users')
          .update({
            'verification_code_hash': codeHash,
            'verification_attempts': 0,
            'verification_code_sent': false,
            'verification_blocked_until': null,
            'verification_status': 'pending',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', userId);

      // Step 4: Insert verification request record (for admin tracking)
      await _client.from('verification_requests').insert({
        'user_id': userId,
        'status': 'pending',
      });

      return VerificationResult(
        success: true,
        message: 'Verification requested. Admin will send your code.',
        code: code, // Plain-text code for admin to see/send
      );
    } catch (e) {
      return VerificationResult(
        success: false,
        message: 'Failed to request verification. Please try again.',
      );
    }
  }

  // ============ SUBMIT VERIFICATION CODE ============

  /// Validates the user-entered code against the stored hash.
  ///
  /// Flow:
  ///   1. Check if verification_code_sent = false → "Code not sent yet"
  ///   2. Check if verification_blocked_until > now → "Locked for X minutes"
  ///   3. Hash the entered code with SHA-256.
  ///   4. Compare with stored verification_code_hash.
  ///   5. If match:
  ///      - Set verification_status = 'approved'
  ///      - Set verified_at = now()
  ///      - Clear verification_code_hash
  ///      - Reset verification_attempts = 0
  ///      - Clear verification_blocked_until
  ///      - Return success
  ///   6. If no match:
  ///      - Increment verification_attempts
  ///      - If attempts >= 5 → set verification_blocked_until = now + 20 minutes
  ///      - Return failure with remaining attempts
  static Future<VerificationResult> submitVerificationCode({
    required String enteredCode,
  }) async {
    try {
      final userId = PreferencesService.getUserId();
      if (userId == null || userId.isEmpty) {
        return VerificationResult(
          success: false,
          message: 'Please log in again.',
        );
      }

      // Fetch current verification state from DB
      final data = await _client
          .from('users')
          .select(
            'verification_code_hash, '
            'verification_code_sent, '
            'verification_attempts, '
            'verification_blocked_until',
          )
          .eq('id', userId)
          .maybeSingle();

      if (data == null) {
        return VerificationResult(success: false, message: 'User not found.');
      }

      // verification_code_sent is BOOLEAN in DB
      final codeSent = data['verification_code_sent'] == true;
      final storedHash = (data['verification_code_hash'] ?? '').toString();
      final attempts = (data['verification_attempts'] ?? 0) as int;
      final blockedUntilStr = data['verification_blocked_until']?.toString();

      // ---- Step 1: Check if code has been sent by admin ----
      if (!codeSent) {
        return VerificationResult(
          success: false,
          message:
              'Your verification code has not been sent yet. Please wait for admin.',
          codePending: true,
        );
      }

      // ---- Step 2: Check brute-force lock ----
      // Lock is determined solely by verification_blocked_until > now
      if (blockedUntilStr != null && blockedUntilStr.isNotEmpty) {
        final blockedUntil = DateTime.tryParse(blockedUntilStr);
        if (blockedUntil != null &&
            blockedUntil.isAfter(DateTime.now().toUtc())) {
          final remaining =
              blockedUntil.difference(DateTime.now().toUtc()).inMinutes + 1;
          return VerificationResult(
            success: false,
            message:
                'Too many attempts. Try again in $remaining minute${remaining == 1 ? "" : "s"}.',
            isLocked: true,
            lockRemainingMinutes: remaining,
          );
        }
      }

      // ---- Step 3: Hash entered code ----
      final enteredHash = _hashCode(enteredCode.trim());

      // ---- Step 4 & 5: Compare hashes ----
      if (enteredHash == storedHash) {
        // ---- CORRECT CODE ----
        await _client
            .from('users')
            .update({
              'verification_status': 'approved',
              'verified_at': DateTime.now().toUtc().toIso8601String(),
              'verification_code_hash': null,
              'verification_attempts': 0,
              'verification_blocked_until': null,
              'verification_code_sent': false,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', userId);

        // Update verification_requests status
        await _client
            .from('verification_requests')
            .update({'status': 'approved'})
            .eq('user_id', userId)
            .eq('status', 'pending');

        return VerificationResult(
          success: true,
          message: 'Your account has been verified!',
        );
      }

      // ---- Step 6: INCORRECT CODE ----
      final newAttempts = attempts + 1;
      final updates = <String, dynamic>{
        'verification_attempts': newAttempts,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      // If 5+ attempts → lock for 20 minutes
      if (newAttempts >= 5) {
        final lockUntil = DateTime.now().toUtc().add(
          const Duration(minutes: 20),
        );
        updates['verification_blocked_until'] = lockUntil.toIso8601String();
      }

      await _client.from('users').update(updates).eq('id', userId);

      final remainingAttempts = 5 - newAttempts;
      if (remainingAttempts > 0) {
        return VerificationResult(
          success: false,
          message:
              'Incorrect code. $remainingAttempts attempt${remainingAttempts == 1 ? "" : "s"} remaining.',
          remainingAttempts: remainingAttempts,
        );
      } else {
        return VerificationResult(
          success: false,
          message: 'Too many incorrect attempts. Locked for 20 minutes.',
          isLocked: true,
          lockRemainingMinutes: 20,
        );
      }
    } catch (e) {
      return VerificationResult(
        success: false,
        message: 'Verification failed. Please try again.',
      );
    }
  }

  // ============ HELPERS ============

  /// Generates a cryptographically secure random 6-digit numeric code.
  static String _generateCode() {
    final random = Random.secure();
    final code = 100000 + random.nextInt(900000); // 100000–999999
    return code.toString();
  }

  /// Hashes a code string using SHA-256 and returns the hex digest.
  static String _hashCode(String code) {
    final bytes = utf8.encode(code.trim());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

// ============ DATA CLASSES ============

/// Full verification state for UI rendering.
class VerificationState {
  final String status; // 'unverified', 'pending', 'approved', 'blocked'
  final bool codeSent; // Admin toggled verification_code_sent = true (BOOLEAN)
  final int attempts; // Current verification_attempts count
  final DateTime? blockedUntil; // verification_blocked_until timestamp
  final bool isLocked; // Computed: blockedUntil != null && blockedUntil > now
  final int lockRemainingSeconds; // Computed: seconds until unlock

  VerificationState({
    required this.status,
    required this.codeSent,
    required this.attempts,
    required this.blockedUntil,
    required this.isLocked,
    required this.lockRemainingSeconds,
  });
}

/// Result of a verification action (request or submit).
class VerificationResult {
  final bool success;
  final String message;
  final String?
  code; // Plain-text code (only set on requestVerification success)
  final bool codePending; // True if admin hasn't sent the code yet
  final bool isLocked; // True if brute-force locked
  final int lockRemainingMinutes; // Minutes until unlock
  final int remainingAttempts; // Attempts left before lock

  VerificationResult({
    required this.success,
    required this.message,
    this.code,
    this.codePending = false,
    this.isLocked = false,
    this.lockRemainingMinutes = 0,
    this.remainingAttempts = 5,
  });
}
