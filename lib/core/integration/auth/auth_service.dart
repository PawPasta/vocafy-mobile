import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../storage/token_storage.dart';

/// Integration-only service:
/// xử lý tương tác Mobile <-> Firebase/Google để lấy token.
class AuthIntegrationService {
  static final AuthIntegrationService _instance = AuthIntegrationService._();
  static AuthIntegrationService get instance => _instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  AuthIntegrationService._();

  Future<String?> getFirebaseIdTokenFromGoogleSignIn() async {
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

    final firebaseIdToken = await userCredential.user?.getIdToken();
    if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
      throw Exception('Không lấy được Firebase ID token');
    }
    return firebaseIdToken;
  }

  Future<String?> getFcmToken() async {
    final cached = await tokenStorage.getFcmToken();
    if (cached != null && cached.isNotEmpty) return cached;

    final live = await FirebaseMessaging.instance.getToken();
    if (live != null && live.isNotEmpty) {
      await tokenStorage.setFcmToken(live);
    }
    return live;
  }

  Future<void> signOutProviderSession() async {
    await _googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();
  }

  Future<bool> isSignedIn() => _googleSignIn.isSignedIn();

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;
}

final authIntegrationService = AuthIntegrationService.instance;
