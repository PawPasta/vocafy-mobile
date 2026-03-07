import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../storage/token_storage.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';

/// Auth Service đơn giản
/// Xử lý Google Sign-In và gọi API
class AuthService {
  static final AuthService _instance = AuthService._();
  static AuthService get instance => _instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  AuthService._();

  /// Đăng nhập bằng Google và gửi idToken lên server
  /// Trả về response data từ server
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      if (kDebugMode) print('🔄 Bắt đầu Google Sign-In...');

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        if (kDebugMode) print('❌ User hủy đăng nhập');
        return null;
      }

      if (kDebugMode) print('✅ Google Sign-In thành công: ${googleUser.email}');

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null || accessToken == null) {
        throw Exception('Không lấy được Google token');
      }

      if (kDebugMode) print('🔄 Đăng nhập Firebase...');

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final firebaseIdToken = await userCredential.user?.getIdToken();
      if (firebaseIdToken == null) {
        throw Exception('Không lấy được Firebase ID token');
      }

      if (kDebugMode) {
        print('✅ Firebase Auth thành công');
        print('🔄 Gửi token lên server...');
      }

      final fcmToken = await tokenStorage.getFcmToken();
      final response = await api.post(Api.loginGoogle, {
        'id_token': firebaseIdToken,
        'fcm_token': fcmToken ?? '',
      });

      if (kDebugMode) print('✅ Server response: ${response.statusCode}');

      final result = response.data['result'];
      if (result is Map) {
        final serverAccessToken =
            (result['accessToken'] ?? result['access_token'])?.toString();
        final refreshToken = (result['refreshToken'] ?? result['refresh_token'])
            ?.toString();

        if (serverAccessToken != null && serverAccessToken.isNotEmpty) {
          await tokenStorage.setAccessToken(serverAccessToken);
          api.setToken(serverAccessToken);
          if (kDebugMode) print('✅ Đã lưu access token');
        }
        if (refreshToken != null && refreshToken.isNotEmpty) {
          await tokenStorage.setRefreshToken(refreshToken);
          if (kDebugMode) print('✅ Đã lưu refresh token');
        }
      }

      return response.data;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      throw Exception('Lỗi xác thực Firebase: ${e.message}');
    } catch (e) {
      if (kDebugMode) print('❌ Sign-In Error: $e');
      rethrow;
    }
  }

  /// Chỉ lấy Google ID Token (không gọi API)
  Future<String?> getGoogleIdToken() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      return googleAuth.idToken;
    } catch (e) {
      if (kDebugMode) print('❌ Get Token Error: $e');
      return null;
    }
  }

  /// Lấy Firebase ID token sau khi đăng nhập Google
  Future<String?> getFirebaseIdToken() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null || accessToken == null) {
        throw Exception('Không lấy được Google token');
      }

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      return await userCredential.user?.getIdToken();
    } catch (e) {
      if (kDebugMode) print('❌ Get Firebase Token Error: $e');
      return null;
    }
  }

  /// Đăng xuất
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();
    api.clearToken();
    await tokenStorage.clearAuthTokens();
  }

  /// Logout server + clear local tokens.
  /// API: POST /api/auth/logout (requires access token in Authorization header)
  Future<void> logout() async {
    try {
      await api.post(Api.logout);
    } catch (e) {
      if (kDebugMode) {
        print('❌ logout API error: $e');
      }
    }
    await signOut();
  }

  Future<bool> isSignedIn() => _googleSignIn.isSignedIn();

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;
}

final authService = AuthService.instance;
