import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/core/notifications/local_notifications.dart';
import 'package:sleepy3/features/sleep_tracking/data/native_sleeping_notification_presenter.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleeping_notification_presenter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(
    NativeSleepingNotificationPresenter.channelName,
  );
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  NativeSleepingNotificationPresenter createPresenter({
    VoidCallback? onOpened,
  }) {
    return NativeSleepingNotificationPresenter(
      LocalNotifications(),
      onOpened: onOpened ?? () {},
    );
  }

  const copy = SleepingNotificationCopy(
    title: 'Durmiendo',
    body: 'Objetivo 8 h · hasta las 07:30',
    ongoingLabel: 'En curso',
    channelName: 'Estado del sueño',
    channelDescription: 'Un temporizador discreto mientras duermes.',
  );

  test('shows the native card with the start and localized copy', () async {
    final presenter = createPresenter();
    final startedAt = DateTime(2026, 10, 20, 23, 15);

    await presenter.show(startedAt: startedAt, copy: copy);

    expect(calls, hasLength(1));
    expect(calls.single.method, 'show');
    final arguments = Map<String, Object?>.from(calls.single.arguments as Map);
    expect(arguments['startedAtMillis'], startedAt.millisecondsSinceEpoch);
    expect(arguments['title'], 'Durmiendo');
    expect(arguments['body'], 'Objetivo 8 h · hasta las 07:30');
    expect(arguments['ongoingLabel'], 'En curso');
    expect(arguments['channelName'], 'Estado del sueño');
    expect(
      arguments['channelDescription'],
      'Un temporizador discreto mientras duermes.',
    );
  });

  test('cancels the native card', () async {
    final presenter = createPresenter();

    await presenter.cancel();

    expect(calls, hasLength(1));
    expect(calls.single.method, 'cancel');
  });

  test('routes a notification tap to the opened callback', () async {
    var opened = 0;
    createPresenter(onOpened: () => opened++);

    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          NativeSleepingNotificationPresenter.channelName,
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('opened'),
          ),
          (_) {},
        );

    expect(opened, 1);
  });
}
