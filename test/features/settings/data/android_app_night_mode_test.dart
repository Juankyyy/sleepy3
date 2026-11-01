import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/settings/data/android_app_night_mode.dart';
import 'package:sleepy3/features/settings/domain/app_theme_mode.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.sleepy3.app/app_night_mode');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('sends the selected mode to the platform channel', () async {
    MethodCall? received;
    messenger.setMockMethodCallHandler(channel, (call) async {
      received = call;
      return null;
    });

    await const AndroidAppNightMode().setMode(AppThemeMode.dark);

    expect(received?.method, 'setApplicationNightMode');
    expect(received?.arguments, {'mode': 'dark'});
  });

  test('ignores a missing platform handler', () async {
    await expectLater(
      const AndroidAppNightMode().setMode(AppThemeMode.light),
      completes,
    );
  });
}
