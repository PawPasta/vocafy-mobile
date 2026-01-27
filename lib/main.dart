import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'config/routes/routes.dart';
import 'config/routes/route_names.dart';

import 'core/api/api_client.dart';
import 'core/notifications/notification_service.dart';
import 'core/storage/token_storage.dart';

final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Push Notification (background)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Init push notifications + FCM token caching
  notificationService.attachNavigatorKey(_navigatorKey);
  await notificationService.init();

  // Load persisted access token for default Authorization header
  final accessToken = await tokenStorage.getAccessToken();
  if (accessToken != null && accessToken.isNotEmpty) {
    api.setToken(accessToken);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vocafy',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      navigatorKey: _navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B7FFF)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      initialRoute: RouteNames.splash,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
