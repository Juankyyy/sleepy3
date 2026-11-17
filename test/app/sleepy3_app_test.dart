import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sleepy3/app/sleepy3_app.dart';
import 'package:sleepy3/app/sleepy3_shell.dart';
import 'package:sleepy3/core/notifications/local_notifications.dart';
import 'package:sleepy3/core/notifications/notification_providers.dart';
import 'package:sleepy3/core/theme/sleepy3_theme.dart';
import 'package:sleepy3/features/health/application/health_connect_gateway_provider.dart';
import 'package:sleepy3/features/health/application/health_sync_store_provider.dart';
import 'package:sleepy3/features/settings/application/language_controller.dart';
import 'package:sleepy3/features/settings/application/theme_mode_controller.dart';
import 'package:sleepy3/features/settings/application/time_format_controller.dart';
import 'package:sleepy3/features/settings/domain/app_language.dart';
import 'package:sleepy3/features/settings/domain/app_theme_mode.dart';
import 'package:sleepy3/features/settings/domain/app_time_format.dart';
import 'package:sleepy3/features/sleep_tracking/application/sleep_tracking_controller.dart';
import 'package:sleepy3/features/sleep_tracking/application/sleeping_notification_controller.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session_store.dart';

import '../core/notifications/fakes.dart';
import '../features/health/fakes.dart';
import '../features/settings/fakes.dart';
import '../features/sleep_tracking/fakes.dart';

void main() {
  Future<FakeSettingsStore> pumpApp(
    WidgetTester tester, {
    required AppThemeMode mode,
    required Brightness platformBrightness,
    AppTimeFormat timeFormat = AppTimeFormat.twelveHour,
    AppLanguage language = AppLanguage.english,
    DateTime Function()? clock,
    FakeSleepingNotificationPresenter? sleepingNotificationPresenter,
    FakeSleepSessionStore? sleepSessionStore,
    LocalNotifications? localNotifications,
    Future<void>? splashStartSignal,
  }) async {
    tester.view.physicalSize = const Size(360, 800) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    tester.platformDispatcher.platformBrightnessTestValue = platformBrightness;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    final settingsStore = FakeSettingsStore();
    final sessionStore = sleepSessionStore ?? FakeSleepSessionStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sleepClockProvider.overrideWithValue(
            clock ?? () => DateTime(2026, 10, 20, 22, 30),
          ),
          sleepSessionStoreProvider.overrideWithValue(sessionStore),
          initialSleepSnapshotProvider.overrideWithValue(
            SleepSnapshot(openSession: sessionStore.snapshot.openSession),
          ),
          sleepingNotificationPresenterProvider.overrideWithValue(
            sleepingNotificationPresenter ??
                FakeSleepingNotificationPresenter(),
          ),
          localNotificationsProvider.overrideWithValue(
            localNotifications ?? FakeNotificationPlatform().build(),
          ),
          healthConnectGatewayProvider.overrideWithValue(
            FakeHealthConnectGateway(),
          ),
          healthSyncStoreProvider.overrideWithValue(FakeHealthSyncStore()),
          settingsStoreProvider.overrideWithValue(settingsStore),
          initialThemeModeProvider.overrideWithValue(mode),
          initialTimeFormatProvider.overrideWithValue(timeFormat),
          initialLanguageProvider.overrideWithValue(language),
        ],
        child: Sleepy3App(
          splashStartSignal: splashStartSignal ?? Future<void>.value(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return settingsStore;
  }

  Brightness appBrightness(WidgetTester tester) {
    final context = tester.element(find.byType(Sleepy3Shell));
    return Theme.of(context).brightness;
  }

  bool appUses24HourFormat(WidgetTester tester) {
    final context = tester.element(find.byType(Sleepy3Shell));
    return MediaQuery.alwaysUse24HourFormatOf(context);
  }

  testWidgets('system follows the platform brightness', (tester) async {
    await pumpApp(
      tester,
      mode: AppThemeMode.system,
      platformBrightness: Brightness.dark,
    );

    expect(appBrightness(tester), Brightness.dark);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();

    expect(appBrightness(tester), Brightness.light);
  });

  testWidgets('dark stays dark regardless of the platform', (tester) async {
    await pumpApp(
      tester,
      mode: AppThemeMode.dark,
      platformBrightness: Brightness.light,
    );

    expect(appBrightness(tester), Brightness.dark);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();

    expect(appBrightness(tester), Brightness.dark);
  });

  testWidgets('light stays light regardless of the platform', (tester) async {
    await pumpApp(
      tester,
      mode: AppThemeMode.light,
      platformBrightness: Brightness.dark,
    );

    expect(appBrightness(tester), Brightness.light);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();

    expect(appBrightness(tester), Brightness.light);
  });

  testWidgets('uses the Sleepy3 light and dark schemes', (tester) async {
    await pumpApp(
      tester,
      mode: AppThemeMode.light,
      platformBrightness: Brightness.dark,
    );

    var context = tester.element(find.byType(Sleepy3Shell));
    var theme = M3ETheme.of(context);
    expect(theme.brightness, Brightness.light);
    expect(theme.colorScheme.primary, Sleepy3Theme.brandIndigo);
    expect(theme.colorScheme.surface, Sleepy3Theme.lightBackground);
    expect(
      theme.typography.baseline.bodyMedium.fontFamily,
      Sleepy3Theme.fontFamily,
    );

    await pumpApp(
      tester,
      mode: AppThemeMode.dark,
      platformBrightness: Brightness.light,
    );

    context = tester.element(find.byType(Sleepy3Shell));
    theme = M3ETheme.of(context);
    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.primary, Sleepy3Theme.darkPrimary);
    expect(theme.colorScheme.surface, Sleepy3Theme.darkBackground);
    expect(theme.colorScheme.primary, isNot(Sleepy3Theme.brandIndigo));
  });

  testWidgets('changing the mode rebuilds the app and persists it', (
    tester,
  ) async {
    final store = await pumpApp(
      tester,
      mode: AppThemeMode.system,
      platformBrightness: Brightness.dark,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Sleepy3Shell)),
    );

    await container
        .read(themeModeControllerProvider.notifier)
        .setMode(AppThemeMode.light);
    await tester.pumpAndSettle();

    expect(appBrightness(tester), Brightness.light);
    expect(store.saves, [AppThemeMode.light]);
  });

  testWidgets('renders the pinned Spanish language', (tester) async {
    await pumpApp(
      tester,
      mode: AppThemeMode.light,
      platformBrightness: Brightness.light,
      language: AppLanguage.spanish,
    );

    expect(find.text('Dormir'), findsOneWidget);
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Estadísticas'), findsOneWidget);
    expect(find.text('Ajustes'), findsOneWidget);
  });

  testWidgets('changing the language rebuilds the app and persists it', (
    tester,
  ) async {
    final store = await pumpApp(
      tester,
      mode: AppThemeMode.light,
      platformBrightness: Brightness.light,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Sleepy3Shell)),
    );

    await container
        .read(languageControllerProvider.notifier)
        .setLanguage(AppLanguage.spanish);
    await tester.pumpAndSettle();

    expect(find.text('Dormir'), findsOneWidget);
    expect(find.text('Ajustes'), findsOneWidget);
    expect(store.languageSaves, [AppLanguage.spanish]);
  });

  testWidgets('applies the saved 24-hour format to the app', (tester) async {
    await pumpApp(
      tester,
      mode: AppThemeMode.light,
      platformBrightness: Brightness.light,
      timeFormat: AppTimeFormat.twentyFourHour,
    );

    expect(appUses24HourFormat(tester), isTrue);
  });

  testWidgets('changing the format rebuilds the app and persists it', (
    tester,
  ) async {
    final store = await pumpApp(
      tester,
      mode: AppThemeMode.light,
      platformBrightness: Brightness.light,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Sleepy3Shell)),
    );

    expect(appUses24HourFormat(tester), isFalse);

    await container
        .read(timeFormatControllerProvider.notifier)
        .setFormat(AppTimeFormat.twentyFourHour);
    await tester.pumpAndSettle();

    expect(appUses24HourFormat(tester), isTrue);
    expect(store.timeFormatSaves, [AppTimeFormat.twentyFourHour]);
  });

  testWidgets('shows and cancels the sleep status notification', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 20, 22, 30);
    final presenter = FakeSleepingNotificationPresenter();
    await pumpApp(
      tester,
      mode: AppThemeMode.light,
      platformBrightness: Brightness.light,
      clock: () => now,
      sleepingNotificationPresenter: presenter,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Sleepy3Shell)),
    );

    await container.read(sleepTrackingControllerProvider.notifier).sleep();
    await tester.pumpAndSettle();

    expect(presenter.shown, hasLength(1));
    expect(presenter.shown.single.startedAt, now);
    expect(presenter.shown.single.copy.title, 'Sleeping');
    expect(presenter.shown.single.copy.body, 'Goal 8h · until 6:30 AM');
    expect(presenter.shown.single.copy.ongoingLabel, 'In progress');

    await container
        .read(languageControllerProvider.notifier)
        .setLanguage(AppLanguage.spanish);
    await tester.pumpAndSettle();

    expect(presenter.shown.last.copy.title, 'Durmiendo');

    await container
        .read(timeFormatControllerProvider.notifier)
        .setFormat(AppTimeFormat.twentyFourHour);
    await tester.pumpAndSettle();

    expect(presenter.shown.last.copy.body, 'Objetivo 8 h · hasta las 06:30');

    now = now.add(const Duration(hours: 8));
    await container.read(sleepTrackingControllerProvider.notifier).wake();
    await tester.pumpAndSettle();

    expect(presenter.cancels, greaterThanOrEqualTo(2));
  });

  testWidgets('the reminder Start sleep action opens a session', (
    tester,
  ) async {
    final sessionStore = FakeSleepSessionStore();
    final presenter = FakeSleepingNotificationPresenter();
    final platform = FakeNotificationPlatform(
      launchDetails: const NotificationAppLaunchDetails(
        true,
        notificationResponse: NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotificationAction,
          id: 1001,
          actionId: startSleepNotificationActionId,
          payload: 'sleep-reminder',
        ),
      ),
    );

    await pumpApp(
      tester,
      mode: AppThemeMode.light,
      platformBrightness: Brightness.light,
      sleepSessionStore: sessionStore,
      sleepingNotificationPresenter: presenter,
      localNotifications: platform.build(),
    );

    expect(sessionStore.starts, hasLength(1));
    expect(
      sessionStore.starts.single.startedAt,
      DateTime(2026, 10, 20, 22, 30),
    );
    expect(presenter.shown, isNotEmpty);
  });

  testWidgets('a running reminder action starts the sleep', (tester) async {
    final sessionStore = FakeSleepSessionStore();
    final platform = FakeNotificationPlatform();

    await pumpApp(
      tester,
      mode: AppThemeMode.light,
      platformBrightness: Brightness.light,
      sleepSessionStore: sessionStore,
      localNotifications: platform.build(),
    );

    platform.emit(
      const NotificationResponse(
        notificationResponseType:
            NotificationResponseType.selectedNotificationAction,
        id: 1001,
        actionId: startSleepNotificationActionId,
        payload: 'sleep-reminder',
      ),
    );
    await tester.pumpAndSettle();

    expect(sessionStore.starts, hasLength(1));
  });

  testWidgets('the sleep card Wake action closes the session', (tester) async {
    final now = DateTime(2026, 10, 21, 7);
    final sessionStore = FakeSleepSessionStore(
      snapshot: SleepSnapshot(
        openSession: SleepSession(
          startedAt: now.subtract(const Duration(hours: 8)),
        ),
      ),
    );

    await pumpApp(
      tester,
      mode: AppThemeMode.light,
      platformBrightness: Brightness.light,
      clock: () => now,
      sleepSessionStore: sessionStore,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Sleepy3Shell)),
    );

    container.read(notificationWakeRequestProvider.notifier).requestWake();
    await tester.pumpAndSettle();

    expect(sessionStore.finishes, [now]);
    expect(container.read(sleepTrackingControllerProvider).openSession, isNull);
  });

  testWidgets('a short Wake from the card asks before discarding', (
    tester,
  ) async {
    final now = DateTime(2026, 10, 21, 7);
    final sessionStore = FakeSleepSessionStore(
      snapshot: SleepSnapshot(
        openSession: SleepSession(
          startedAt: now.subtract(const Duration(minutes: 5)),
        ),
      ),
    );

    await pumpApp(
      tester,
      mode: AppThemeMode.light,
      platformBrightness: Brightness.light,
      clock: () => now,
      sleepSessionStore: sessionStore,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Sleepy3Shell)),
    );

    container.read(notificationWakeRequestProvider.notifier).requestWake();
    await tester.pumpAndSettle();

    expect(find.text('Sleep too short'), findsOneWidget);
    expect(sessionStore.discards, 0);

    await tester.tap(find.text('Keep sleeping'));
    await tester.pumpAndSettle();

    expect(sessionStore.discards, 0);
    expect(
      container.read(sleepTrackingControllerProvider).openSession,
      isNotNull,
    );

    container.read(notificationWakeRequestProvider.notifier).requestWake();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard session'));
    await tester.pumpAndSettle();

    expect(sessionStore.discards, 1);
    expect(container.read(sleepTrackingControllerProvider).openSession, isNull);
  });

  testWidgets('a cold-start Wake waits for the splash before asking', (
    tester,
  ) async {
    final now = DateTime(2026, 10, 21, 7);
    final splashSignal = Completer<void>();
    final sessionStore = FakeSleepSessionStore(
      snapshot: SleepSnapshot(
        openSession: SleepSession(
          startedAt: now.subtract(const Duration(minutes: 5)),
        ),
      ),
    );

    await pumpApp(
      tester,
      mode: AppThemeMode.light,
      platformBrightness: Brightness.light,
      clock: () => now,
      sleepSessionStore: sessionStore,
      splashStartSignal: splashSignal.future,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Sleepy3Shell)),
    );

    container.read(notificationWakeRequestProvider.notifier).requestWake();
    await tester.pump();

    expect(find.text('Sleep too short'), findsNothing);

    splashSignal.complete();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Sleep too short'), findsOneWidget);
  });
}
