import 'package:flutter/material.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/login/login_screen.dart';
import '../../features/home/home_screen.dart';
import 'route_names.dart';

/// Main app routes configuration
class AppRoutes {
  // Private constructor to prevent instantiation
  AppRoutes._();
  
  /// Generate routes for the app
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.splash:
        return _buildRoute(const SplashScreen());
      
      case RouteNames.onboarding:
        return _buildRoute(const OnboardingScreen());
      
      case RouteNames.home:
        return _buildRoute(const HomeScreen());
      
      case RouteNames.login:
        return _buildRoute(const LoginScreen());
      
      default:
        return _buildRoute(
          _ErrorScreen(routeName: settings.name ?? 'Unknown'),
        );
    }
  }
  
  /// Build route with fade transition
  static MaterialPageRoute _buildRoute(Widget page) {
    return MaterialPageRoute(builder: (_) => page);
  }
  
  /// Build route with custom transition
  static PageRouteBuilder buildRouteWithTransition(
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
    RouteTransitionType transitionType = RouteTransitionType.fade,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        switch (transitionType) {
          case RouteTransitionType.fade:
            return FadeTransition(opacity: animation, child: child);
          
          case RouteTransitionType.slide:
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            final tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          
          case RouteTransitionType.scale:
            return ScaleTransition(
              scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              ),
              child: child,
            );
          
          case RouteTransitionType.rotation:
            return RotationTransition(
              turns: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              ),
              child: child,
            );
        }
      },
    );
  }
}

/// Route transition types
enum RouteTransitionType {
  fade,
  slide,
  scale,
  rotation,
}

/// Error screen for undefined routes
class _ErrorScreen extends StatelessWidget {
  final String routeName;
  
  const _ErrorScreen({required this.routeName});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              'Route not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              'Route name: $routeName',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
