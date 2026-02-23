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

      // Cache locally
      await _cacheUserLocally(
        name: fullName,
        phone: phone,
        email: email,
        role: role,
      );

      return AuthResult(
        success: true,
        message: 'Account created! Please verify your email.',
        needsVerification: true,
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

      if (response.user!.emailConfirmedAt == null) {
        return AuthResult(
          success: false,
          message: 'Please verify your email first.',
          needsVerification: true,
        );
      }

      // Sync profile to local
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
  static Future<AuthResult> deleteAccount() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return AuthResult(success: false, message: 'No user logged in.');
      }

      await _client.from('profiles').delete().eq('id', user.id);
      await signOut();

      return AuthResult(success: true, message: 'Account deleted.');
    } catch (e) {
      return AuthResult(success: false, message: 'Failed to delete account.');
    }
  }

  // ============ RESEND VERIFICATION ============
  static Future<AuthResult> resendVerificationEmail(String email) async {
    try {
      await _client.auth.resend(type: OtpType.signup, email: email);
      return AuthResult(success: true, message: 'Verification email sent!');
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Failed to send email. Try again.',
      );
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
  static bool isLoggedIn() {
    return _client.auth.currentUser != null;
  }

  static bool isEmailVerified() {
    return _client.auth.currentUser?.emailConfirmedAt != null;
  }

  static String? getCurrentUserId() {
    return _client.auth.currentUser?.id;
  }

  static String? getCurrentEmail() {
    return _client.auth.currentUser?.email;
  }

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
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final Map<String, dynamic> updates = {
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updates['full_name'] = fullName;
      if (age != null) updates['age'] = age;
      if (phone != null) updates['phone'] = phone;
      if (email != null) updates['email'] = email;

      await _client.from('profiles').update(updates).eq('id', user.id);

      if (fullName != null) await PreferencesService.setUserName(fullName);
      if (age != null) await PreferencesService.setUserAge(age);
      if (phone != null) await PreferencesService.setUserPhone(phone);
      if (email != null) await PreferencesService.setUserEmail(email);
    } catch (e) {
      rethrow;
    }
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
    if (msg.contains('email not confirmed')) {
      return 'Please verify your email first.';
    }
    if (msg.contains('too many requests') || msg.contains('rate limit')) {
      return 'Too many attempts. Please wait a moment.';
    }
    if (msg.contains('weak password') || msg.contains('password')) {
      return 'Password must be at least 6 characters.';
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
