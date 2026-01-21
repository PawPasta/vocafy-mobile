import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
      // 1. Sign in với Google
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User hủy

      // 2. Lấy ID Token
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Không lấy được ID Token');
      }

      // Log trong debug mode
      if (kDebugMode) {
        print('🔑 Google ID Token: $idToken');
        print('📧 Email: ${googleUser.email}');
      }

      // 3. Gửi idToken lên server
      final response = await api.post(Api.loginGoogle, {'idToken': idToken});

      // 4. Lưu token từ server (nếu có)
      if (response.data['accessToken'] != null) {
        api.setToken(response.data['accessToken']);
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

  /// Đăng xuất
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    api.clearToken();
  }

  /// Kiểm tra đã đăng nhập Google chưa
  Future<bool> isSignedIn() => _googleSignIn.isSignedIn();

  /// User Google hiện tại
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;
}

/// Shortcut
final authService = AuthService.instance;
