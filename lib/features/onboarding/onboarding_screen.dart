import 'package:flutter/material.dart';
import 'models/onboarding_model.dart';
import 'widgets/onboarding_page_widget.dart';
import '../../config/routes/route_names.dart';
import '../../core/storage/token_storage.dart';

/// Onboarding screen with multiple pages and smooth animations
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  int _currentPage = 0;
  final int _totalPages = OnboardingModel.pages.length;

  @override
  void initState() {
    super.initState();

    _pageController = PageController();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  /// Handle page change and restart fade animation
  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });

    _fadeController.reset();
    _fadeController.forward();
  }

  /// Navigate to next page or complete onboarding
  void _onNextPressed() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  /// Navigate to previous page
  void _onBackPressed() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Skip all pages and complete onboarding
  void _onSkipPressed() {
    _completeOnboarding();
  }

  /// Complete onboarding and navigate to main app
  Future<void> _completeOnboarding() async {
    await tokenStorage.setHasCompletedOnboarding(true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _totalPages,
                itemBuilder: (context, index) {
                  return OnboardingPageWidget(
                    page: OnboardingModel.pages[index],
                    animation: _fadeAnimation,
                  );
                },
              ),
            ),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  /// Build header with logo, back button, and skip button
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button (only show after first page)
          SizedBox(
            width: 40,
            height: 40,
            child: _currentPage > 0
                ? IconButton(
                    onPressed: _onBackPressed,
                    icon: const Icon(Icons.arrow_back, color: Colors.grey),
                    padding: EdgeInsets.zero,
                  )
                : const SizedBox.shrink(),
          ),

          // Logo in center
          Image.asset(
            'lib/assets/images/Logo.png',
            height: 32,
            fit: BoxFit.contain,
          ),

          // Skip button (hide on last page)
          SizedBox(
            width: 60,
            child: TextButton(
              onPressed: _onSkipPressed,
              child: Text(
                'Skip',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build bottom section with page indicators and next button
  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [_buildPageIndicators(), _buildNextButton()],
      ),
    );
  }

  /// Build animated page indicators
  Widget _buildPageIndicators() {
    return Row(
      children: List.generate(_totalPages, (index) {
        final isActive = index == _currentPage;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF5B7FFF) : const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  /// Build next/finish button with animation
  Widget _buildNextButton() {
    return GestureDetector(
      onTap: _onNextPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5B7FFF), Color(0xFF4C6FFF)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5B7FFF).withAlpha(77),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_forward_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
