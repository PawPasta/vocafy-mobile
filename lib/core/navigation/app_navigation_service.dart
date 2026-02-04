import 'package:flutter/material.dart';

import '../../config/routes/route_names.dart';

class AppNavigationService {
  static final AppNavigationService _instance = AppNavigationService._();
  static AppNavigationService get instance => _instance;

  AppNavigationService._();

  GlobalKey<NavigatorState>? _navigatorKey;

  void attachNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  void goToLogin() {
    final nav = _navigatorKey?.currentState;
    if (nav == null) return;

    nav.pushNamedAndRemoveUntil(RouteNames.login, (route) => false);
  }

  void goToHome() {
    final nav = _navigatorKey?.currentState;
    if (nav == null) return;

    nav.pushNamedAndRemoveUntil(RouteNames.home, (route) => false);
  }
}

final appNavigationService = AppNavigationService.instance;
