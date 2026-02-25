import 'package:supabase_flutter/supabase_flutter.dart';
import 'preferences_service.dart';

class AuthService {
  static final _client = Supabase.instance.client;

  // ============ SIGN UP ============
  static Future<AuthResult> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'phone': phone, 'role': role},
      );

      if (response.user == null) {
        return AuthResult(
          success: false,
          message: 'Sign up failed. Please try again.',
        );
      }

      // Cache local UI info
      await _cacheUserLocally(
        name: fullName,
        phone: phone,
        email: email,
        role: role,
      );

      // Send OTP email via Edge Function (custom 6-digit OTP)
      // NOTE: Requires GitHub-deployed edge function: send-email-otp
      try {
        await _client.functions.invoke('send-email-otp');
      } catch (_) {
        // If email provider not configured yet, signup can still succeed,
        // but user won't receive OTP. We'll show a clear message.
        return AuthResult(
          success: true,
          needsVerification: true,
          message: 'Account created, but failed to send OTP email. Try resend.',
        );
      }

      return AuthResult(
        success: true,
        needsVerification: true,
        message: 'Verification code sent to your email!',
      );
    } on AuthException catch (e) {
      return AuthResult(success: false, message: _parseAuthError(e.message));
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  // ============ VERIFY OTP (CUSTOM) ============
  // We do NOT use _client.auth.verifyOTP for this flow.
  static Future<AuthResult> verifyOTP({
    required String email, // kept for UI; not required by backend now
    required String otp,
  }) async {
    try {
      // verify_email_otp sets profiles.email_verified=true
      final ok = await _client.rpc('verify_email_otp', params: {'p_code': otp});

      if (ok != true) {
        return AuthResult(
          success: false,
          message: 'Invalid code. Please try again.',
        );
      }

      await syncProfileToLocal();
      return AuthResult(success: true, message: 'Email verified!');
    } on AuthException catch (e) {
      return AuthResult(success: false, message: _parseAuthError(e.message));
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Verification failed. Please try again.',
      );
    }
  }

  // ============ RESEND OTP (CUSTOM) ============
  static Future<AuthResult> resendOTP(String email) async {
    try {
      await _client.functions.invoke('send-email-otp');
      return AuthResult(success: true, message: 'New code sent!');
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Failed to resend. Please try again in a moment.',
      );
    }
  }

  // ============ SIGN IN ============
  static Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return AuthResult(
          success: false,
          message: 'Login failed. Please try again.',
        );
      }

      // Check OUR verification flag (profiles.email_verified)
      final profile = await _client
          .from('profiles')
          .select('email_verified')
          .eq('id', response.user!.id)
          .single();

      final verified = profile['email_verified'] == true;
      if (!verified) {
        // Optional: auto-send OTP again on login
        try {
          await _client.functions.invoke('send-email-otp');
        } catch (_) {}

        return AuthResult(
          success: false,
          message: 'Please verify your email first.',
          needsVerification: true,
        );
      }

      await syncProfileToLocal();
      return AuthResult(success: true, message: 'Welcome back!');
    } on AuthException catch (e) {
      return AuthResult(success: false, message: _parseAuthError(e.message));
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  // ============ SIGN OUT ============
  static Future<void> signOut() async {
    await _client.auth.signOut();
    await PreferencesService.clearAll();
  }

  // ============ DELETE ACCOUNT ============
  // NOTE: Your current DB RLS does not allow deleting profiles directly (and it
  // won't delete auth.users). We'll implement proper full delete later via RPC/Edge Function.
  static Future<AuthResult> deleteAccount() async {
    return AuthResult(
      success: false,
      message:
          'Account deletion will be implemented with admin-grade wipe soon.',
    );
  }

  // ============ PASSWORD RESET ============
  static Future<AuthResult> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      return AuthResult(success: true, message: 'Reset email sent!');
    } catch (e) {
      return AuthResult(success: false, message: 'Failed to send reset email.');
    }
  }

  // ============ STATE CHECKS ============
  static bool isLoggedIn() => _client.auth.currentUser != null;

  // Old method is not valid anymore because we disabled Supabase email confirmation.
  // Keep it but return "true" only if session exists; use isEmailVerifiedRemote for real status.
  static bool isEmailVerified() => _client.auth.currentUser != null;

  static Future<bool> isEmailVerifiedRemote() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;
    final profile = await _client
        .from('profiles')
        .select('email_verified')
        .eq('id', user.id)
        .single();
    return profile['email_verified'] == true;
  }

  static String? getCurrentUserId() => _client.auth.currentUser?.id;
  static String? getCurrentEmail() => _client.auth.currentUser?.email;

  // ============ SYNC PROFILE ============
  static Future<void> syncProfileToLocal() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      await _cacheUserLocally(
        name: data['full_name'] ?? '',
        phone: data['phone'] ?? '',
        email: data['email'] ?? user.email ?? '',
        role: data['role'] ?? 'customer',
      );
    } catch (_) {}
  }

  static Future<void> updateProfile({
    String? fullName,
    int? age,
    String? phone,
    String? email,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
      if (fullName != null) 'full_name': fullName,
      if (age != null) 'age': age,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
    };

    await _client.from('profiles').update(updates).eq('id', user.id);

    if (fullName != null) await PreferencesService.setUserName(fullName);
    if (age != null) await PreferencesService.setUserAge(age);
    if (phone != null) await PreferencesService.setUserPhone(phone);
    if (email != null) await PreferencesService.setUserEmail(email);
  }

  // ============ HELPERS ============
  static Future<void> _cacheUserLocally({
    required String name,
    required String phone,
    required String email,
    required String role,
  }) async {
    await PreferencesService.setUserName(name);
    await PreferencesService.setUserPhone(phone);
    await PreferencesService.setUserEmail(email);
    await PreferencesService.setUserRole(role);
    await PreferencesService.setRegistered(true);
  }

  static String _parseAuthError(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('already registered') ||
        msg.contains('already been registered')) {
      return 'This email is already registered. Try signing in.';
    }
    if (msg.contains('invalid login') ||
        msg.contains('invalid email or password')) {
      return 'Incorrect email or password.';
    }
    if (msg.contains('too many requests') || msg.contains('rate limit')) {
      return 'Too many attempts. Please wait a moment.';
    }
    if (msg.contains('weak password') || msg.contains('password')) {
      return 'Password is too weak.';
    }
    if (msg.contains('invalid email')) {
      return 'Please enter a valid email address.';
    }
    return message;
  }
}

class AuthResult {
  final bool success;
  final String message;
  final bool needsVerification;

  AuthResult({
    required this.success,
    required this.message,
    this.needsVerification = false,
  });
}
