import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocafy_mobile/screen/learning/pronunciation_challenge_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const permissionChannel = MethodChannel('flutter.baseflow.com/permissions/methods');
  const ttsChannel = MethodChannel('flutter_tts');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionChannel, (call) async {
          if (call.method == 'requestPermissions') {
            return <int, int>{7: 0}; // microphone denied
          }
          if (call.method == 'checkPermissionStatus') {
            return 0;
          }
          return null;
        });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, (call) async {
          if (call.method == 'setSpeechRate') return 1;
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, null);
  });

  testWidgets('shows message when microphone permission is denied', (
    tester,
  ) async {
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PronunciationChallengeDialog(
            termText: 'こんにちは',
            isFinalStage: false,
            currentStage: 1,
            onComplete: () => completed = true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Microphone permission is required'), findsOneWidget);
    expect(find.text('Tap the mic to start speaking'), findsNothing);
    expect(completed, isFalse);
  });
}

