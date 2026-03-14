import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../assets/app_remote_images.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/data/services/auth_service.dart';
import '../../../core/data/network/api_client.dart';
import '../../../config/routes/route_names.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _primaryBlue = Color(0xFF5B7FFF);
  static const Color _primaryBlueDark = Color(0xFF4C6FFF);
  static const Color _pageBg = Colors.white;
  static const Color _softErrorOrange = Color(0xFFF4A261);

  bool _isLoading = false;

  Future<void> _onGoogleSignInPressed() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      // Sử dụng signInWithGoogle() - đã xử lý đầy đủ:
      // 1. Google Sign-In
      // 2. Firebase Auth
      // 3. Gửi token lên server
      // 4. Lưu access/refresh token
      final response = await authService.signInWithGoogle();

      if (!mounted) return;

      if (response == null) {
        // User hủy đăng nhập
        setState(() => _isLoading = false);
        return;
      }

      // Thành công - chuyển đến home
      Navigator.pushNamedAndRemoveUntil(
        context,
        RouteNames.home,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      final errorMessage = _extractPreferredLoginErrorMessage(e);
      if (errorMessage == null || errorMessage.isEmpty) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: _softErrorOrange,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _extractPreferredLoginErrorMessage(Object error) {
    // API errors: always prioritize server-provided message.
    if (error is DioException) {
      final apiMessage = _extractApiMessage(error);
      if (apiMessage != null) return apiMessage;
      if (_looksLikeDebugNoise(error.toString())) return null;
      return 'Login failed. Please try again.';
    }

    // Keep current behavior for Firebase/Google integration issues: do not show.
    if (_isFirebaseOrProviderError(error)) return null;

    final raw = error.toString().replaceFirst('Exception: ', '').trim();
    if (raw.isEmpty || _looksLikeDebugNoise(raw)) return null;
    return raw;
  }

  String? _extractApiMessage(DioException error) {
    final responseData = error.response?.data;
    if (responseData is Map) {
      final message = (responseData['message'] ??
              responseData['error'] ??
              responseData['detail'])
          ?.toString()
          .trim();
      if (message != null && message.isNotEmpty) return message;
    }

    if (responseData is String && responseData.trim().isNotEmpty) {
      return responseData.trim();
    }

    final wrapped = error.error;
    if (wrapped is ApiServerException && wrapped.message.trim().isNotEmpty) {
      return wrapped.message.trim();
    }

    return null;
  }

  bool _isFirebaseOrProviderError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('firebase') ||
        msg.contains('google_sign_in') ||
        msg.contains('google sign in') ||
        msg.contains('platformexception(sign_in') ||
        msg.contains('com.google.android.gms');
  }

  bool _looksLikeDebugNoise(String value) {
    final msg = value.toLowerCase();
    return msg.contains('dioexception') ||
        msg.contains('stacktrace') ||
        msg.contains('debug');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      _buildLogo(),
                      const SizedBox(height: 34),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 78),
                          _buildHero(),
                          const SizedBox(height: 22),
                          _buildTitle(),
                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildBottomPanel(context),
              ],
            ),
          ),
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.4),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(_primaryBlue),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Signing in...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Image.network(
        AppRemoteImages.appIconPng,
        height: 36,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildHero() {
    return SizedBox(
      height: 360,
      child: Center(
        child: Image.network(
          AppRemoteImages.loginHeroPng,
          height: 340,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          colors: [_primaryBlue, _primaryBlueDark],
        ).createShader(bounds);
      },
      child: const Text(
        'Get ready to learn!',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, 24, 24, 18 + bottomInset),
      constraints: const BoxConstraints(minHeight: 130),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_primaryBlue, _primaryBlueDark],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(26),
          topRight: Radius.circular(26),
        ),
      ),
      child: Center(child: _buildGoogleButton(context)),
    );
  }

  Widget _buildGoogleButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _primaryBlueDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: _isLoading ? null : _onGoogleSignInPressed,
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_primaryBlueDark),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildGoogleMark(),
                  const SizedBox(width: 10),
                  const Text(
                    'Sign in with Google',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildGoogleMark() {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      alignment: Alignment.center,
      child: const FaIcon(
        FontAwesomeIcons.google,
        size: 14,
        color: Color(0xFF4285F4),
      ),
    );
  }
}
