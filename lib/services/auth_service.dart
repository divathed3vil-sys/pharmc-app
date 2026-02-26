import 'package:supabase_flutter/supabase_flutter.dart';
import 'preferences_service.dart';

class AuthService {
  static final _client = Supabase.instance.client;

  // ============ SIGN UP ============
  // No email OTP verification anymore.
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

      // Cache immediately so UI can proceed
      await _cacheUserLocally(
        name: fullName,
        phone: phone,
        email: email,
        role: role,
      );

      // Try to sync from DB profile (trigger creates profiles row)
      await syncProfileToLocal();

      return AuthResult(
        success: true,
        message: 'Account created successfully.',
        needsVerification: false,
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

      // No email-confirm gate now
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
  // Uses Edge Function: delete-my-account (service role on server).
  static Future<AuthResult> deleteAccount() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return AuthResult(success: false, message: 'No user logged in.');
      }

      final resp = await _client.functions.invoke('delete-my-account');

      // Ensure local logout & wipe
      await signOut();

      final data = resp.data;
      final ok = data is Map && data['ok'] == true;

      if (ok) {
        return AuthResult(success: true, message: 'Account deleted.');
      }

      return AuthResult(success: false, message: 'Failed to delete account.');
    } catch (e) {
      return AuthResult(success: false, message: 'Failed to delete account.');
    }
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
          .maybeSingle();

      if (data == null) return;

      await _cacheUserLocally(
        name: data['full_name'] ?? '',
        phone: data['phone'] ?? '',
        email: data['email'] ?? user.email ?? '',
        role: data['role'] ?? 'customer',
      );

      // Store age too (if you use it)
      final age = data['age'];
      if (age is int) {
        await PreferencesService.setUserAge(age);
      }
    } catch (_) {}
  }

  static Future<void> updateProfile({
    String? fullName,
    int? age,
    String? phone,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
      if (fullName != null) 'full_name': fullName,
      if (age != null) 'age': age,
      if (phone != null) 'phone': phone,
    };

    await _client.from('profiles').update(updates).eq('id', user.id);

    if (fullName != null) await PreferencesService.setUserName(fullName);
    if (age != null) await PreferencesService.setUserAge(age);
    if (phone != null) await PreferencesService.setUserPhone(phone);
  }

  // ============ OLD OTP METHODS (STUBS for now) ============
  // We keep these temporarily so the project still compiles
  // until we delete email_verification_screen.dart.
  static Future<AuthResult> verifyOTP({
    required String email,
    required String otp,
  }) async {
    return AuthResult(
      success: false,
      message: 'Email OTP verification removed.',
      needsVerification: false,
    );
  }

  static Future<AuthResult> resendOTP(String email) async {
    return AuthResult(
      success: false,
      message: 'Email OTP verification removed.',
      needsVerification: false,
    );
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

    // Ensure language always exists (since Sinhala/Tamil are locked)
    final lang = PreferencesService.getLanguage();
    if (lang.isEmpty) {
      await PreferencesService.setLanguage('en');
    }
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
