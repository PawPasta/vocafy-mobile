import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

/// Splash screen displayed on app launch with animated logo
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    _rotateAnimation = Tween<double>(
      begin: -0.1,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
    ));

    _shimmerAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(_shimmerController);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    _navigateToOnboarding();
  }

  /// Navigate to onboarding screen after splash animation
  Future<void> _navigateToOnboarding() async {
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;
    
    Navigator.pushReplacementNamed(context, '/onboarding');
  }

  @override
  void dispose() {
    _animationController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8F9FA),
              Color(0xFFFFFFFF),
              Color(0xFFF0F4FF),
            ],
          ),
        ),
        child: Stack(
          children: [
            ..._buildBackgroundParticles(),
            
            Center(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotateAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: child,
                      ),
                    ),
                  );
                },
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: _buildLogoWithEffects(),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBackgroundParticles() {
    return List.generate(15, (index) {
      final random = math.Random(index);
      final size = random.nextDouble() * 80 + 40;
      final left = random.nextDouble() * 400;
      final top = random.nextDouble() * 800;
      final delay = random.nextInt(1000);
      
      return Positioned(
        left: left,
        top: top,
        child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 2000 + delay),
          curve: Curves.easeInOut,
          builder: (context, double value, child) {
            return Opacity(
              opacity: (value * 0.1).clamp(0.0, 0.1),
              child: Transform.translate(
                offset: Offset(0, math.sin(value * math.pi * 2) * 20),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF5B7FFF).withAlpha(77),
                        const Color(0xFF4CAF50).withAlpha(26),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }


  Widget _buildLogoWithEffects() {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: 250 * _pulseAnimation.value,
              height: 120 * _pulseAnimation.value,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5B7FFF).withAlpha(51),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withAlpha(38),
                    blurRadius: 60,
                    spreadRadius: 15,
                  ),
                ],
              ),
            );
          },
        ),
        
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) {
              return ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [
                      _shimmerAnimation.value - 0.3,
                      _shimmerAnimation.value,
                      _shimmerAnimation.value + 0.3,
                    ].map((e) => e.clamp(0.0, 1.0)).toList(),
                    colors: const [
                      Colors.transparent,
                      Colors.white54,
                      Colors.transparent,
                    ],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.srcATop,
                child: child,
              );
            },
            child: _buildVocafyLogo(),
          ),
        ),
        
        _buildVocafyLogo(),
      ],
    );
  }

  Widget _buildVocafyLogo() {
    return Image.asset(
      'lib/assets/images/Logo.png',
      width: 200,
      height: 80,
      fit: BoxFit.contain,
    );
  }
}
