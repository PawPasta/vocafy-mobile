import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static final TokenStorage _instance = TokenStorage._();
  static TokenStorage get instance => _instance;

  TokenStorage._();

  static const _kAccessTokenKey = 'access_token';
  static const _kRefreshTokenKey = 'refresh_token';
  static const _kFcmTokenKey = 'fcm_token';
  static const _kHasCompletedOnboardingKey = 'has_completed_onboarding';

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

  /// Whether the user has already completed/skip onboarding at least once.
  /// If true, app should bypass splash/onboarding on next launches.
  Future<bool> getHasCompletedOnboarding() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_kHasCompletedOnboardingKey) ?? false;
  }

  Future<void> setHasCompletedOnboarding(bool value) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_kHasCompletedOnboardingKey, value);
  }
}

final tokenStorage = TokenStorage.instance;
