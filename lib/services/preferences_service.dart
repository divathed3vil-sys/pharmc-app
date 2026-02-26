import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static SharedPreferences? _prefs;

  // Initialize — call this once when app starts
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ============ ROLE ============
  static Future<void> setUserRole(String role) async {
    await _prefs?.setString('user_role', role);
  }

  static String? getUserRole() {
    return _prefs?.getString('user_role');
  }

  // ============ REGISTRATION STATUS ============
  static Future<void> setRegistered(bool value) async {
    await _prefs?.setBool('is_registered', value);
  }

  static bool isRegistered() {
    return _prefs?.getBool('is_registered') ?? false;
  }

  // ============ USER INFO (Local Cache) ============
  static Future<void> setUserName(String name) async {
    await _prefs?.setString('user_name', name);
  }

  static String? getUserName() {
    return _prefs?.getString('user_name');
  }

  static Future<void> setUserAge(int age) async {
    await _prefs?.setInt('user_age', age);
  }

  static int? getUserAge() {
    return _prefs?.getInt('user_age');
  }

  static Future<void> setUserPhone(String phone) async {
    await _prefs?.setString('user_phone', phone);
  }

  static String? getUserPhone() {
    return _prefs?.getString('user_phone');
  }

  static Future<void> setUserEmail(String email) async {
    await _prefs?.setString('user_email', email);
  }

  static String? getUserEmail() {
    return _prefs?.getString('user_email');
  }

  // ============ APP SETTINGS ============
  static Future<void> setDarkMode(String mode) async {
    // 'system', 'light', 'dark'
    await _prefs?.setString('dark_mode', mode);
  }

  static String getDarkMode() {
    return _prefs?.getString('dark_mode') ?? 'system';
  }

  static Future<void> setUiScale(String scale) async {
    // 'normal', 'medium', 'large'
    await _prefs?.setString('ui_scale', scale);
  }

  static String getUiScale() {
    return _prefs?.getString('ui_scale') ?? 'normal';
  }

  static Future<void> setNotificationsEnabled(bool value) async {
    await _prefs?.setBool('notifications_enabled', value);
  }

  static bool getNotificationsEnabled() {
    return _prefs?.getBool('notifications_enabled') ?? true;
  }

  static Future<void> setLanguage(String lang) async {
    // 'en', 'si', 'ta'
    await _prefs?.setString('language', lang);
  }

  static String getLanguage() {
    return _prefs?.getString('language') ?? 'en';
  }

  // ============ DRAFT PROMPT ============
  static const String _keyDraftPromptShown = 'draft_prompt_shown';

  static bool getDraftPromptShown() {
    return _prefs?.getBool(_keyDraftPromptShown) ?? false;
  }

  static Future<void> setDraftPromptShown(bool value) async {
    await _prefs?.setBool(_keyDraftPromptShown, value);
  }

  // ============ VERIFY POPUP SNOOZE (24h) ============
  static const String _keyVerifyPopupSnoozeUntil = 'verify_popup_snooze_until';

  static DateTime? getVerifyPopupSnoozeUntil() {
    final iso = _prefs?.getString(_keyVerifyPopupSnoozeUntil);
    if (iso == null) return null;
    return DateTime.tryParse(iso);
  }

  static Future<void> snoozeVerifyPopupFor24h() async {
    final until = DateTime.now().add(const Duration(hours: 24));
    await _prefs?.setString(
      _keyVerifyPopupSnoozeUntil,
      until.toIso8601String(),
    );
  }

  static Future<void> clearVerifyPopupSnooze() async {
    await _prefs?.remove(_keyVerifyPopupSnoozeUntil);
  }

  // ============ CLEAR ALL (Logout) ============
  static Future<void> clearAll() async {
    await _prefs?.clear();
  }
}
