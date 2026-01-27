import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/storage/token_storage.dart';

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
      // 1. Sign in với Google
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User hủy

      // 2. Lấy Google tokens
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null || accessToken == null) {
        throw Exception('Không lấy được Google token');
      }

      // 3. Đăng nhập Firebase bằng credential
      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      // 4. Lấy Firebase ID token để gửi server
      final firebaseIdToken = await userCredential.user?.getIdToken();
      if (firebaseIdToken == null) {
        throw Exception('Không lấy được Firebase ID token');
      }

      // Log trong debug mode
      if (kDebugMode) {
        print('🔑 Firebase ID Token: $firebaseIdToken');
        print('📧 Email: ${googleUser.email}');
      }

      // 5. Gửi Firebase ID token lên server
      final fcmToken = await tokenStorage.getFcmToken();
      final response = await api.post(Api.loginGoogle, {
        'id_token': firebaseIdToken,
        'fcm_token': fcmToken ?? '',
      });

      // 4. Lưu token từ server (nếu có)
      final result = response.data['result'];
      if (result is Map) {
        final accessToken = (result['accessToken'] ?? result['access_token'])
            ?.toString();
        final refreshToken = (result['refreshToken'] ?? result['refresh_token'])
            ?.toString();

        if (accessToken != null && accessToken.isNotEmpty) {
          await tokenStorage.setAccessToken(accessToken);
          api.setToken(accessToken);
        }
        if (refreshToken != null && refreshToken.isNotEmpty) {
          await tokenStorage.setRefreshToken(refreshToken);
        }
      }

      return response.data;
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

  /// Kiểm tra đã đăng nhập Google chưa
  Future<bool> isSignedIn() => _googleSignIn.isSignedIn();

  /// User Google hiện tại
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;
}

/// Shortcut
final authService = AuthService.instance;
