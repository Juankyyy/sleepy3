import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/health/data/method_channel_app_info_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(MethodChannelAppInfoGateway.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('returns the app label and caches it per package', () async {
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls++;
      expect(call.method, 'appLabelForPackage');
      expect(call.arguments, {
        'packageName': 'com.google.android.apps.healthdata',
      });
      return 'Google Health';
    });

    final gateway = MethodChannelAppInfoGateway();

    expect(
      await gateway.appLabelForPackage(' com.google.android.apps.healthdata '),
      'Google Health',
    );
    expect(
      await gateway.appLabelForPackage('com.google.android.apps.healthdata'),
      'Google Health',
    );
    expect(calls, 1);
  });

  test(
    'returns null for a blank package without touching the platform',
    () async {
      var calls = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls++;
        return 'Google Health';
      });

      final gateway = MethodChannelAppInfoGateway();

      expect(await gateway.appLabelForPackage('   '), isNull);
      expect(calls, 0);
    },
  );

  test('returns null when the platform bridge is missing', () async {
    final gateway = MethodChannelAppInfoGateway();

    expect(
      await gateway.appLabelForPackage('com.google.android.apps.healthdata'),
      isNull,
    );
  });
}
