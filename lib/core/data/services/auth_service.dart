import 'package:flutter/foundation.dart';

import '../../integration/auth/auth_service.dart';
import '../../storage/token_storage.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';

/// Data-layer auth service:
/// nhận token từ integration và xử lý tương tác server/session server.
class AuthService {
  static final AuthService _instance = AuthService._();
  static AuthService get instance => _instance;

  AuthService._();

  Future<Map<String, dynamic>?> signInWithGoogle() async {
    final firebaseIdToken =
        await authIntegrationService.getFirebaseIdTokenFromGoogleSignIn();
    if (firebaseIdToken == null) return null;

    final fcmToken = await authIntegrationService.getFcmToken();
    final response = await api.post(Api.loginGoogle, {
      'id_token': firebaseIdToken,
      'fcm_token': fcmToken ?? '',
    });

    final data = response.data;
    if (data is! Map<String, dynamic>) return null;

    final result = data['result'];
    if (result is Map) {
      final serverAccessToken =
          (result['accessToken'] ?? result['access_token'])?.toString();
      final refreshToken =
          (result['refreshToken'] ?? result['refresh_token'])?.toString();

      if (serverAccessToken != null && serverAccessToken.isNotEmpty) {
        await tokenStorage.setAccessToken(serverAccessToken);
        api.setToken(serverAccessToken);
      }

      if (refreshToken != null && refreshToken.isNotEmpty) {
        await tokenStorage.setRefreshToken(refreshToken);
      }
    }

    return data;
  }

  Future<void> logout() async {
    try {
      await api.post(Api.logout);
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('❌ logout API error: $e');
      }
    }

    await authIntegrationService.signOutProviderSession();
    api.clearToken();
    await tokenStorage.clearAuthTokens();
  }
}

final authService = AuthService.instance;
