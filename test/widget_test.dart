import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocafy_mobile/config/routes/route_names.dart';
import 'package:vocafy_mobile/config/routes/routes.dart';

void main() {
  testWidgets('Routes: unknown route renders error screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/unknown-route',
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Route not found'), findsOneWidget);
  });

  test('RouteNames values are stable', () {
    expect(RouteNames.splash, '/');
    expect(RouteNames.login, '/login');
  });
}
