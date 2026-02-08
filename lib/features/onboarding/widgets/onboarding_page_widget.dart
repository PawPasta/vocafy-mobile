import 'package:flutter/material.dart';
import '../models/onboarding_model.dart';

/// Widget for displaying a single onboarding page with image and content
class OnboardingPageWidget extends StatelessWidget {
  final OnboardingModel page;
  final Animation<double> animation;

  const OnboardingPageWidget({
    super.key,
    required this.page,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            // Illustration image with hero animation
            Hero(
              tag: page.imagePath,
              child: Image.network(
                page.imagePath,
                height: 280,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 280,
                  child: Center(
                    child: Icon(Icons.image_not_supported, size: 44),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 60),

            // Title with gradient text effect
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF5B7FFF), Color(0xFF4C6FFF)],
              ).createShader(bounds),
              child: Text(
                page.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.3,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Description text
            Text(
              page.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.6,
                letterSpacing: 0.3,
              ),
            ),

            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}
