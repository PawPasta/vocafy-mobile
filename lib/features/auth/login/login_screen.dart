import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  static const Color _primaryBlue = Color(0xFF5B7FFF);
  static const Color _primaryBlueDark = Color(0xFF4C6FFF);
  static const Color _pageBg = Colors.white;

  void _onGoogleSignInPressed(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google sign-in not yet implemented')),
    );
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
      child: Center(
        child: _buildGoogleButton(context),
      ),
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
        onPressed: () => _onGoogleSignInPressed(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGoogleMark(),
            const SizedBox(width: 10),
            const Text(
              'Sign in with Google',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
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
