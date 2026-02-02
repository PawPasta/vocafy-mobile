import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/enrollment_service.dart';
import '../../../core/storage/token_storage.dart';
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

  bool _isLoading = false;

  /// Gọi API get focused enrollment và lưu syllabus ID vào storage
  /// Chỉ chạy 1 lần sau khi login thành công
  Future<void> _loadFocusedEnrollment() async {
    try {
      final focused = await enrollmentService.getFocusedEnrollment();
      // Lưu syllabus ID đang focus vào storage (clear nếu server không có focus)
      await tokenStorage.setFocusedSyllabusId(focused?.syllabusId);

      // Đánh dấu đã load xong để không cần gọi lại
      await tokenStorage.setFocusedSyllabusLoaded(true);
    } catch (e) {
      // Không set loaded để home/learning có thể retry sau.
    }
  }

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

      // Login thành công → Gọi API get focused enrollment và lưu vào storage
      // Không block UI login; vẫn đảm bảo chỉ gọi đúng 1 lần.
      unawaited(_loadFocusedEnrollment());

      // Thành công - chuyển đến home
      Navigator.pushNamedAndRemoveUntil(
        context,
        RouteNames.home,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Login failed: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
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
      child: Image.asset(
        'lib/assets/images/Logo.png',
        height: 36,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildHero() {
    return SizedBox(
      height: 360,
      child: Center(
        child: Image.asset(
          'lib/assets/images/login_img.png',
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
