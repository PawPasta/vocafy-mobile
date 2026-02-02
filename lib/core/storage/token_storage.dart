import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static final TokenStorage _instance = TokenStorage._();
  static TokenStorage get instance => _instance;

  TokenStorage._();

  static const _kAccessTokenKey = 'access_token';
  static const _kRefreshTokenKey = 'refresh_token';
  static const _kFcmTokenKey = 'fcm_token';
  static const _kFocusedSyllabusIdKey = 'focused_syllabus_id';
  static const _kFocusedSyllabusLoadedKey = 'focused_syllabus_loaded';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> setAccessToken(String? value) async {
    final prefs = await _getPrefs();
    if (value == null || value.isEmpty) {
      await prefs.remove(_kAccessTokenKey);
      return;
    }
    await prefs.setString(_kAccessTokenKey, value);
  }

  Future<String?> getAccessToken() async {
    final prefs = await _getPrefs();
    return prefs.getString(_kAccessTokenKey);
  }

  Future<void> setRefreshToken(String? value) async {
    final prefs = await _getPrefs();
    if (value == null || value.isEmpty) {
      await prefs.remove(_kRefreshTokenKey);
      return;
    }
    await prefs.setString(_kRefreshTokenKey, value);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await _getPrefs();
    return prefs.getString(_kRefreshTokenKey);
  }

  Future<void> setFcmToken(String? value) async {
    final prefs = await _getPrefs();
    if (value == null || value.isEmpty) {
      await prefs.remove(_kFcmTokenKey);
      return;
    }
    await prefs.setString(_kFcmTokenKey, value);
  }

  Future<String?> getFcmToken() async {
    final prefs = await _getPrefs();
    return prefs.getString(_kFcmTokenKey);
  }

  Future<void> clearAuthTokens() async {
    final prefs = await _getPrefs();
    await prefs.remove(_kAccessTokenKey);
    await prefs.remove(_kRefreshTokenKey);
  }

  /// Set focused syllabus ID
  Future<void> setFocusedSyllabusId(int? value) async {
    final prefs = await _getPrefs();
    if (value == null) {
      await prefs.remove(_kFocusedSyllabusIdKey);
      return;
    }
    await prefs.setInt(_kFocusedSyllabusIdKey, value);
  }

  /// Get focused syllabus ID
  Future<int?> getFocusedSyllabusId() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_kFocusedSyllabusIdKey);
  }

  /// Check if focused syllabus has been loaded (first time login)
  Future<bool> isFocusedSyllabusLoaded() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_kFocusedSyllabusLoadedKey) ?? false;
  }

  /// Mark focused syllabus as loaded
  Future<void> setFocusedSyllabusLoaded(bool value) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_kFocusedSyllabusLoadedKey, value);
  }

  /// Clear focused syllabus data (call on logout)
  Future<void> clearFocusedSyllabus() async {
    final prefs = await _getPrefs();
    await prefs.remove(_kFocusedSyllabusIdKey);
    await prefs.remove(_kFocusedSyllabusLoadedKey);
  }
}

final tokenStorage = TokenStorage.instance;
