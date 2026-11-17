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
  String? readyAction;

  setUp(() {
    calls.clear();
    readyAction = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'ready') return readyAction;
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  NativeSleepingNotificationPresenter createPresenter({
    VoidCallback? onOpened,
    VoidCallback? onWake,
  }) {
    return NativeSleepingNotificationPresenter(
      LocalNotifications(),
      onOpened: onOpened ?? () {},
      onWake: onWake ?? () {},
    );
  }

  List<MethodCall> callsTo(String method) {
    return calls.where((call) => call.method == method).toList();
  }

  const copy = SleepingNotificationCopy(
    title: 'Durmiendo',
    body: 'Objetivo 8 h · hasta las 07:30',
    ongoingLabel: 'En curso',
    wakeActionLabel: 'Despertar',
    channelName: 'Estado del sueño',
    channelDescription: 'Un temporizador discreto mientras duermes.',
  );

  test('shows the native card with the start and localized copy', () async {
    final presenter = createPresenter();
    final startedAt = DateTime(2026, 10, 20, 23, 15);

    await presenter.show(startedAt: startedAt, copy: copy);

    final showCalls = callsTo('show');
    expect(showCalls, hasLength(1));
    final arguments = Map<String, Object?>.from(
      showCalls.single.arguments as Map,
    );
    expect(arguments['startedAtMillis'], startedAt.millisecondsSinceEpoch);
    expect(arguments['title'], 'Durmiendo');
    expect(arguments['body'], 'Objetivo 8 h · hasta las 07:30');
    expect(arguments['ongoingLabel'], 'En curso');
    expect(arguments['wakeActionLabel'], 'Despertar');
    expect(arguments['channelName'], 'Estado del sueño');
    expect(
      arguments['channelDescription'],
      'Un temporizador discreto mientras duermes.',
    );
  });

  test('cancels the native card', () async {
    final presenter = createPresenter();

    await presenter.cancel();

    expect(callsTo('cancel'), hasLength(1));
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

  test('routes the card Wake action to the wake callback', () async {
    var woke = 0;
    createPresenter(onWake: () => woke++);

    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          NativeSleepingNotificationPresenter.channelName,
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('wake'),
          ),
          (_) {},
        );

    expect(woke, 1);
  });

  test('applies a Wake tapped while the app was starting', () async {
    readyAction = 'wake';
    var woke = 0;
    createPresenter(onWake: () => woke++);

    await Future<void>.delayed(Duration.zero);

    expect(callsTo('ready'), hasLength(1));
    expect(woke, 1);
  });
}
