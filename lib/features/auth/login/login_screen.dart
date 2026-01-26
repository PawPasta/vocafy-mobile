import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../data/data.dart';
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

  Future<void> _onGoogleSignInPressed() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      // 1. Lấy Firebase ID Token (sau khi đăng nhập Google qua Firebase Auth)
      final firebaseIdToken = await authService.getFirebaseIdToken();

      if (firebaseIdToken == null) {
        // User hủy đăng nhập
        if (mounted) setState(() => _isLoading = false);
        return;
      }

        // 2. Gửi Firebase ID token về server dạng JSON body
          final response =
            await api.post(Api.loginGoogle, {'id_token': firebaseIdToken});

      if (!mounted) return;

      // 3. Xử lý response từ server
      if (response.data != null) {
        // Lưu access token từ server (nếu có)
        final result = response.data['result'];
        if (result is Map && result['accessToken'] != null) {
          api.setToken(result['accessToken']);
        }

        // Thành công - chuyển đến home
        Navigator.pushNamedAndRemoveUntil(
          context,
          RouteNames.home,
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đăng nhập thất bại: $e'),
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
      body: SafeArea(
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
