import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import 'preferences_service.dart';

class AuthService {
  static final _client = Supabase.instance.client;
  static const _storage = FlutterSecureStorage();
  static const _deviceIdKey = 'pharmc_device_id';
  static const _userIdKey = 'pharmc_user_id';

  // ============ DEVICE ID ============
  static Future<String> _getOrCreateDeviceId() async {
    String? deviceId = await _storage.read(key: _deviceIdKey);
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = const Uuid().v4();
      await _storage.write(key: _deviceIdKey, value: deviceId);
    }
    return deviceId;
  }

  static Future<void> _clearDeviceId() async {
    await _storage.delete(key: _deviceIdKey);
  }

  static Future<void> _storeUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  static Future<String?> _readUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  static Future<void> _clearUserId() async {
    await _storage.delete(key: _userIdKey);
  }

  // ============ SIGN UP ============
  static Future<AuthResult> signUp({
    required String phone,
    required String fullName,
    required String dateOfBirth,
    String? email,
    String role = 'customer',
  }) async {
    try {
      final dob = DateTime.tryParse(dateOfBirth);
      if (dob == null) {
        return AuthResult(success: false, message: 'Invalid date of birth.');
      }

      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }

      if (age < 18) {
        return AuthResult(
          success: false,
          message: 'You must be at least 18 years old.',
        );
      }

      final existing = await _client
          .from('users')
          .select('id')
          .eq('phone', phone)
          .maybeSingle();

      if (existing != null) {
        return AuthResult(
          success: false,
          message: 'This phone number is already registered. Try signing in.',
        );
      }

      final userId = const Uuid().v4();

      await _client.from('users').insert({
        'id': userId,
        'phone': phone,
        'full_name': fullName,
        'email': email,
        'date_of_birth': dateOfBirth,
        'age': age,
        'role': role,
        'verification_status': 'unverified',
        'is_blocked': false,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      final deviceId = await _getOrCreateDeviceId();
      try {
        await _client.from('user_devices').insert({
          'user_id': userId,
          'device_id': deviceId,
          'last_active_at': DateTime.now().toUtc().toIso8601String(),
        });
      } catch (e) {
        if (_isDeviceLimitError(e)) {
          return AuthResult(
            success: false,
            message:
                'Maximum device limit reached for this account. '
                'Please contact admin for approval.',
            needsApproval: true,
          );
        }
        rethrow;
      }

      await _storeUserId(userId);

      await _cacheUserLocally(
        userId: userId,
        name: fullName,
        phone: phone,
        email: email ?? '',
        role: role,
        dateOfBirth: dateOfBirth,
        age: age,
      );

      return AuthResult(
        success: true,
        message: 'Account created successfully.',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  // ============ SIGN IN (phone-only) ============
  static Future<AuthResult> signIn({required String phone}) async {
    try {
      final data = await _client
          .from('users')
          .select()
          .eq('phone', phone)
          .maybeSingle();

      if (data == null) {
        return AuthResult(
          success: false,
          message: 'No account found with this phone number.',
        );
      }

      // Check if blocked — return dedicated blocked result
      final isBlocked = data['is_blocked'] == true;
      if (isBlocked) {
        final reason = (data['blocked_reason'] ?? '').toString().trim();

        // Still cache phone so BlockedAccountScreen can use it
        await PreferencesService.setUserPhone(phone);

        return AuthResult(
          success: false,
          message: reason.isNotEmpty
              ? reason
              : 'Your account has been blocked.',
          isBlocked: true,
          blockedReason: reason.isNotEmpty ? reason : null,
        );
      }

      final userId = data['id'].toString();
      final deviceId = await _getOrCreateDeviceId();

      final existingDevice = await _client
          .from('user_devices')
          .select('id')
          .eq('user_id', userId)
          .eq('device_id', deviceId)
          .maybeSingle();

      if (existingDevice != null) {
        await _client
            .from('user_devices')
            .update({
              'last_active_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('device_id', deviceId);
      } else {
        try {
          await _client.from('user_devices').insert({
            'user_id': userId,
            'device_id': deviceId,
            'last_active_at': DateTime.now().toUtc().toIso8601String(),
          });
        } catch (e) {
          if (_isDeviceLimitError(e)) {
            return AuthResult(
              success: false,
              message:
                  'Maximum 4 devices reached. Please contact admin for approval.',
              needsApproval: true,
            );
          }
          rethrow;
        }
      }

      await _storeUserId(userId);

      await _cacheUserLocally(
        userId: userId,
        name: (data['full_name'] ?? '').toString(),
        phone: (data['phone'] ?? '').toString(),
        email: (data['email'] ?? '').toString(),
        role: (data['role'] ?? 'customer').toString(),
        dateOfBirth: (data['date_of_birth'] ?? '').toString(),
        age: data['age'] is int ? data['age'] : 0,
      );

      return AuthResult(success: true, message: 'Welcome back!');
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  // ============ SIGN OUT ============
  static Future<void> signOut() async {
    try {
      final userId = await _readUserId();
      final deviceId = await _storage.read(key: _deviceIdKey);
      if (deviceId != null &&
          deviceId.isNotEmpty &&
          userId != null &&
          userId.isNotEmpty) {
        await _client
            .from('user_devices')
            .delete()
            .eq('user_id', userId)
            .eq('device_id', deviceId);
      }
    } catch (_) {}

    await _clearUserId();
    await PreferencesService.clearAll();
  }

  /// Light sign-out: clears local session only.
  /// Does NOT delete server device rows.
  /// Used when a blocked user signs out — we don't want to modify server state.
  static Future<void> signOutLocalOnly() async {
    await _clearUserId();
    await PreferencesService.clearAll();
  }

  // ============ DELETE ACCOUNT ============
  static Future<AuthResult> deleteAccount() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null || userId.isEmpty) {
        return AuthResult(success: false, message: 'No user logged in.');
      }

      await _client.from('user_devices').delete().eq('user_id', userId);
      await _client.from('users').delete().eq('id', userId);

      await _clearDeviceId();
      await _clearUserId();
      await PreferencesService.clearAll();

      return AuthResult(success: true, message: 'Account deleted.');
    } catch (e) {
      return AuthResult(success: false, message: 'Failed to delete account.');
    }
  }

  // ============ PASSWORD RESET ============
  static Future<AuthResult> resetPassword(String phone) async {
    return AuthResult(
      success: false,
      message: 'Password reset not yet implemented.',
    );
  }

  // ============ STATE CHECKS ============
  static bool isLoggedIn() {
    final userId = PreferencesService.getUserId();
    return userId != null && userId.isNotEmpty;
  }

  static String? getCurrentUserId() {
    final id = PreferencesService.getUserId();
    return (id != null && id.isNotEmpty) ? id : null;
  }

  static String? getCurrentEmail() {
    final email = PreferencesService.getUserEmail();
    return (email != null && email.isNotEmpty) ? email : null;
  }

  static String? getCurrentPhone() {
    final phone = PreferencesService.getUserPhone();
    return (phone != null && phone.isNotEmpty) ? phone : null;
  }

  // ============ SESSION VALIDATION (server-side) ============
  static Future<SessionResult> validateSession() async {
    try {
      final deviceId = await _storage.read(key: _deviceIdKey);
      if (deviceId == null || deviceId.isEmpty) {
        return SessionResult(valid: false, reason: 'no_device');
      }

      final record = await _client
          .from('user_devices')
          .select('user_id')
          .eq('device_id', deviceId)
          .maybeSingle();

      if (record == null) {
        await _clearUserId();
        await PreferencesService.clearAll();
        return SessionResult(valid: false, reason: 'device_not_found');
      }

      final userId = record['user_id'].toString();

      await _storeUserId(userId);
      await PreferencesService.setUserId(userId);

      final userData = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (userData == null) {
        await _clearUserId();
        await PreferencesService.clearAll();
        return SessionResult(valid: false, reason: 'user_deleted');
      }

      if (userData['is_blocked'] == true) {
        final reason = (userData['blocked_reason'] ?? '').toString().trim();

        // Cache user phone so BlockedAccountScreen can reference it
        final userPhone = (userData['phone'] ?? '').toString();
        if (userPhone.isNotEmpty) {
          await PreferencesService.setUserPhone(userPhone);
        }

        return SessionResult(
          valid: false,
          reason: 'blocked',
          blockedReason: reason.isNotEmpty ? reason : null,
        );
      }

      await _client
          .from('user_devices')
          .update({'last_active_at': DateTime.now().toUtc().toIso8601String()})
          .eq('device_id', deviceId)
          .eq('user_id', userId);

      await _cacheUserLocally(
        userId: userId,
        name: (userData['full_name'] ?? '').toString(),
        phone: (userData['phone'] ?? '').toString(),
        email: (userData['email'] ?? '').toString(),
        role: (userData['role'] ?? 'customer').toString(),
        dateOfBirth: (userData['date_of_birth'] ?? '').toString(),
        age: userData['age'] is int ? userData['age'] : 0,
      );

      return SessionResult(valid: true, reason: 'valid');
    } catch (_) {
      return SessionResult(valid: false, reason: 'error');
    }
  }

  // ============ SYNC PROFILE ============
  static Future<void> syncProfileToLocal() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return;

      final data = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return;

      await _cacheUserLocally(
        userId: userId,
        name: (data['full_name'] ?? '').toString(),
        phone: (data['phone'] ?? '').toString(),
        email: (data['email'] ?? '').toString(),
        role: (data['role'] ?? 'customer').toString(),
        dateOfBirth: (data['date_of_birth'] ?? '').toString(),
        age: data['age'] is int ? data['age'] : 0,
      );
    } catch (_) {}
  }

  static Future<void> updateProfile({
    String? fullName,
    int? age,
    String? phone,
    String? email,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) return;

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (fullName != null) updates['full_name'] = fullName;
    if (age != null) updates['age'] = age;
    if (phone != null) updates['phone'] = phone;
    if (email != null) updates['email'] = email;

    await _client.from('users').update(updates).eq('id', userId);

    if (fullName != null) await PreferencesService.setUserName(fullName);
    if (age != null) await PreferencesService.setUserAge(age);
    if (phone != null) await PreferencesService.setUserPhone(phone);
    if (email != null) await PreferencesService.setUserEmail(email);
  }

  // ============ ACCOUNT SHARING ============

  static Future<ShareResult> generateShareCode() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null || userId.isEmpty) {
        return ShareResult(success: false, message: 'No user logged in.');
      }

      final code = _generateShareCode();

      await _client
          .from('users')
          .update({
            'share_code': code,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', userId);

      return ShareResult(
        success: true,
        message: 'Share code generated.',
        shareCode: code,
      );
    } catch (e) {
      return ShareResult(
        success: false,
        message: 'Failed to generate share code.',
      );
    }
  }

  static Future<String?> getShareCode() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null || userId.isEmpty) return null;

      final data = await _client
          .from('users')
          .select('share_code')
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;
      final code = data['share_code'];
      if (code == null || code.toString().isEmpty) return null;
      return code.toString();
    } catch (_) {
      return null;
    }
  }

  static Future<ShareResult> clearShareCode() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null || userId.isEmpty) {
        return ShareResult(success: false, message: 'No user logged in.');
      }

      await _client
          .from('users')
          .update({
            'share_code': null,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', userId);

      return ShareResult(success: true, message: 'Share code revoked.');
    } catch (e) {
      return ShareResult(
        success: false,
        message: 'Failed to revoke share code.',
      );
    }
  }

  static Future<ShareResult> joinSharedAccount({
    required String shareCode,
  }) async {
    try {
      final data = await _client
          .from('users')
          .select()
          .eq('share_code', shareCode.trim())
          .maybeSingle();

      if (data == null) {
        return ShareResult(
          success: false,
          message: 'Invalid share code. Please check and try again.',
        );
      }

      if (data['is_blocked'] == true) {
        return ShareResult(
          success: false,
          message: 'This account is blocked. Cannot join.',
        );
      }

      final userId = data['id'].toString();
      final deviceId = await _getOrCreateDeviceId();

      final existingDevice = await _client
          .from('user_devices')
          .select('id')
          .eq('user_id', userId)
          .eq('device_id', deviceId)
          .maybeSingle();

      if (existingDevice != null) {
        await _client
            .from('user_devices')
            .update({
              'last_active_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('device_id', deviceId);

        await _storeUserId(userId);
        await _cacheUserLocally(
          userId: userId,
          name: (data['full_name'] ?? '').toString(),
          phone: (data['phone'] ?? '').toString(),
          email: (data['email'] ?? '').toString(),
          role: (data['role'] ?? 'customer').toString(),
          dateOfBirth: (data['date_of_birth'] ?? '').toString(),
          age: data['age'] is int ? data['age'] : 0,
        );

        return ShareResult(
          success: true,
          message: 'Already joined this account.',
        );
      }

      try {
        await _client.from('user_devices').insert({
          'user_id': userId,
          'device_id': deviceId,
          'last_active_at': DateTime.now().toUtc().toIso8601String(),
        });
      } catch (e) {
        if (_isDeviceLimitError(e)) {
          return ShareResult(
            success: false,
            message:
                'This account has reached the maximum of 4 devices. '
                'Ask the account owner to remove a device first.',
            needsApproval: true,
          );
        }
        rethrow;
      }

      await _client
          .from('users')
          .update({
            'share_code': null,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', userId);

      await _storeUserId(userId);

      await _cacheUserLocally(
        userId: userId,
        name: (data['full_name'] ?? '').toString(),
        phone: (data['phone'] ?? '').toString(),
        email: (data['email'] ?? '').toString(),
        role: (data['role'] ?? 'customer').toString(),
        dateOfBirth: (data['date_of_birth'] ?? '').toString(),
        age: data['age'] is int ? data['age'] : 0,
      );

      return ShareResult(
        success: true,
        message: 'Successfully joined shared account!',
      );
    } catch (e) {
      return ShareResult(
        success: false,
        message: 'Failed to join. Please try again.',
      );
    }
  }

  // ============ DEVICE HELPERS ============

  static bool _isDeviceLimitError(Object e) {
    final msg = e.toString().toUpperCase();
    if (msg.contains('DEVICE_LIMIT_REACHED')) return true;

    if (e is PostgrestException) {
      final detail = (e.message ?? '').toUpperCase();
      final hint = (e.details?.toString() ?? '').toUpperCase();
      final code = (e.code ?? '').toUpperCase();
      if (detail.contains('DEVICE_LIMIT_REACHED') ||
          hint.contains('DEVICE_LIMIT_REACHED') ||
          code.contains('DEVICE_LIMIT_REACHED')) {
        return true;
      }
    }

    return false;
  }

  static String _generateShareCode() {
    final random = Random.secure();
    final code = 100000 + random.nextInt(900000);
    return code.toString();
  }

  // ============ CACHE HELPERS ============
  static Future<void> _cacheUserLocally({
    required String userId,
    required String name,
    required String phone,
    required String email,
    required String role,
    String dateOfBirth = '',
    int age = 0,
  }) async {
    await PreferencesService.setUserId(userId);
    await PreferencesService.setUserName(name);
    await PreferencesService.setUserPhone(phone);
    await PreferencesService.setUserEmail(email);
    await PreferencesService.setUserRole(role);
    await PreferencesService.setRegistered(true);

    if (dateOfBirth.isNotEmpty) {
      await PreferencesService.setDateOfBirth(dateOfBirth);
    }
    if (age > 0) {
      await PreferencesService.setUserAge(age);
    }

    final lang = PreferencesService.getLanguage();
    if (lang.isEmpty) {
      await PreferencesService.setLanguage('en');
    }
  }
}

// ============ DATA CLASSES ============

class AuthResult {
  final bool success;
  final String message;
  final bool needsVerification;
  final bool needsApproval;
  final bool isBlocked;
  final String? blockedReason;

  AuthResult({
    required this.success,
    required this.message,
    this.needsVerification = false,
    this.needsApproval = false,
    this.isBlocked = false,
    this.blockedReason,
  });
}

class SessionResult {
  final bool valid;
  final String reason;
  final String? blockedReason;

  SessionResult({
    required this.valid,
    required this.reason,
    this.blockedReason,
  });
}

class ShareResult {
  final bool success;
  final String message;
  final String? shareCode;
  final bool needsApproval;

  ShareResult({
    required this.success,
    required this.message,
    this.shareCode,
    this.needsApproval = false,
  });
}
