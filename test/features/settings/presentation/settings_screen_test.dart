import 'dart:ui' show Tristate;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sleepy3/core/theme/sleepy3_theme.dart';
import 'package:sleepy3/features/health/application/health_connect_gateway_provider.dart';
import 'package:sleepy3/features/health/application/health_sync_controller.dart';
import 'package:sleepy3/features/health/application/health_sync_store_provider.dart';
import 'package:sleepy3/features/health/application/sleep_data_source_controller.dart';
import 'package:sleepy3/features/health/domain/health_connect_gateway.dart';
import 'package:sleepy3/features/health/domain/health_sleep_session.dart';
import 'package:sleepy3/features/health/domain/sleep_data_source.dart';
import 'package:sleepy3/features/reminders/application/sleep_reminder_controller.dart';
import 'package:sleepy3/features/reminders/domain/sleep_reminder.dart';
import 'package:sleepy3/features/settings/application/app_version_provider.dart';
import 'package:sleepy3/features/settings/application/language_controller.dart';
import 'package:sleepy3/features/settings/domain/app_language.dart';
import 'package:sleepy3/features/settings/domain/app_theme_mode.dart';
import 'package:sleepy3/features/settings/domain/app_time_format.dart';
import 'package:sleepy3/features/settings/domain/app_version.dart';
import 'package:sleepy3/features/settings/presentation/settings_screen.dart';
import 'package:sleepy3/features/sleep_tracking/application/sleep_tracking_providers.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';
import 'package:sleepy3/l10n/l10n.dart';

import '../../health/fakes.dart';
import '../../reminders/fakes.dart';
import '../fakes.dart';
import '../../sleep_tracking/fakes.dart';

void main() {
  setUpAll(() async {
    // Render with the bundled font so the 360dp/200% checks use production
    // metrics instead of the test font's square glyphs.
    final loader = FontLoader('SpaceGrotesk');
    loader.addFont(
      rootBundle.load('assets/fonts/SpaceGrotesk-VariableFont.ttf'),
    );
    await loader.load();
  });

  Future<FakeSettingsStore> pumpSettings(
    WidgetTester tester, {
    AppThemeMode initial = AppThemeMode.system,
    AppTimeFormat initialTimeFormat = AppTimeFormat.twelveHour,
    AppLanguage initialLanguage = AppLanguage.english,
    SleepDataSource source = SleepDataSource.local,
    SleepReminder initialReminder = SleepReminder.defaults,
    AppVersion? version,
    FakeSettingsStore? store,
    FakeHealthConnectGateway? gateway,
    FakeHealthSyncStore? healthSyncStore,
    FakeSleepReminderScheduler? reminderScheduler,
    double textScale = 1,
    Size size = const Size(360, 800),
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final settingsStore = store ?? FakeSettingsStore(sleepDataSource: source);
    final data = Sleepy3Theme.light();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsStoreProvider.overrideWithValue(settingsStore),
          initialThemeModeProvider.overrideWithValue(initial),
          initialTimeFormatProvider.overrideWithValue(initialTimeFormat),
          initialLanguageProvider.overrideWithValue(initialLanguage),
          initialSleepDataSourceProvider.overrideWithValue(source),
          initialSleepReminderProvider.overrideWithValue(initialReminder),
          sleepReminderSchedulerProvider.overrideWithValue(
            reminderScheduler ?? FakeSleepReminderScheduler(),
          ),
          healthConnectGatewayProvider.overrideWithValue(
            gateway ?? FakeHealthConnectGateway(),
          ),
          healthSyncStoreProvider.overrideWithValue(
            healthSyncStore ?? FakeHealthSyncStore(),
          ),
          sleepSessionStoreProvider.overrideWithValue(FakeSleepSessionStore()),
          sleepClockProvider.overrideWithValue(
            () => DateTime(2026, 10, 21, 6, 20),
          ),
          appVersionProvider.overrideWithValue(version),
        ],
        child: Consumer(
          builder: (context, ref, child) {
            final language = ref.watch(languageControllerProvider);
            return M3EMaterialApp(
              title: 'Sleepy3',
              data: data,
              theme: data.toThemeData(),
              locale: language.locale,
              localizationsDelegates: appLocalizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(body: SettingsScreen()),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    // The app refreshes the connection on launch and resume, after the splash;
    // this standalone screen gets that same refresh.
    await ProviderScope.containerOf(tester.element(find.byType(SettingsScreen)))
        .read(healthSyncControllerProvider.notifier)
        .refresh();
    await tester.pumpAndSettle();
    return settingsStore;
  }

  // Labels sit inside the row's tappable surface, so the label itself is not
  // the hit target. Tapping its center still activates the row.
  Future<void> tapLabel(WidgetTester tester, String label) async {
    final finder = find.text(label);
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        160,
        scrollable: find.byType(Scrollable).first,
      );
    } else {
      await tester.ensureVisible(finder.first);
    }
    await tester.pumpAndSettle();
    await tester.tap(finder, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  Future<void> scrollToLabel(
    WidgetTester tester,
    String label, {
    double delta = 160,
  }) async {
    final finder = find.text(label);
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        delta,
        scrollable: find.byType(Scrollable).first,
      );
    } else {
      await tester.ensureVisible(finder.first);
    }
    await tester.pumpAndSettle();
  }

  Future<void> tapDialogLabel(WidgetTester tester, String label) async {
    final finder = find.descendant(
      of: find.byType(M3EDialog),
      matching: find.text(label),
    );
    await tester.tap(finder.last, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  Future<void> chooseSource(WidgetTester tester, String label) async {
    await tapLabel(tester, 'Source');
    await tapDialogLabel(tester, label);
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows appearance, sleep data and about sections', (
    tester,
  ) async {
    await pumpSettings(
      tester,
      version: const AppVersion(version: '0.1.0', buildNumber: '1'),
    );

    expect(find.text('Settings'), findsOneWidget);
    final title = tester.widget<Text>(find.text('Settings'));
    expect(title.style?.fontFamily, Sleepy3Theme.brandFontFamily);
    expect(title.style?.fontVariations!.single.value, 28);
    expect(
      find.text('Theme, reminders, sleep data and app info.'),
      findsOneWidget,
    );
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Reminders'), findsOneWidget);
    expect(find.text('Sleep reminder'), findsOneWidget);
    expect(find.text('Off'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Time format'), findsOneWidget);
    expect(find.text('12-hour'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Sleep data'), findsOneWidget);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Local'), findsOneWidget);
    expect(find.text('Import'), findsOneWidget);
    expect(find.textContaining('Download from Google Health'), findsOneWidget);

    await scrollToLabel(tester, 'Google Health');
    expect(find.text('Google Health'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);

    await scrollToLabel(tester, 'Add');
    expect(find.text('Sync'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);

    await scrollToLabel(tester, 'About');
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('On-device only.'), findsOneWidget);
    expect(find.text('Version'), findsOneWidget);
    expect(find.text('0.1.0 (1)'), findsOneWidget);

    await scrollToLabel(tester, 'Licenses');
    expect(find.text('Licenses'), findsOneWidget);
  });

  testWidgets('announces the sleep reminder as a switch', (tester) async {
    final handle = tester.ensureSemantics();
    try {
      await pumpSettings(tester);

      final node = tester.getSemantics(find.bySemanticsLabel('Sleep reminder'));
      final data = node.getSemanticsData();

      expect(data.flagsCollection.isToggled, Tristate.isFalse);
    } finally {
      handle.dispose();
    }
  });

  testWidgets(
    'enabling the sleep reminder requests permission and schedules it',
    (tester) async {
      final scheduler = FakeSleepReminderScheduler();
      final store = await pumpSettings(tester, reminderScheduler: scheduler);

      await tapLabel(tester, 'Sleep reminder');

      expect(scheduler.permissionRequests, 1);
      expect(scheduler.scheduled, hasLength(1));
      expect(
        scheduler.scheduled.single.reminder,
        const SleepReminder(enabled: true, hour: 22, minute: 0),
      );
      expect(store.reminderSaves.single.enabled, isTrue);
      expect(tester.widget<M3ESwitch>(find.byType(M3ESwitch)).value, isTrue);
      expect(find.text('Every day at 10:00 PM'), findsOneWidget);
      expect(find.text('Reminder time'), findsOneWidget);
      expect(find.text('10:00 PM'), findsOneWidget);
    },
  );

  testWidgets('denied notification permission keeps the reminder off', (
    tester,
  ) async {
    final scheduler = FakeSleepReminderScheduler(permissionGranted: false);
    final store = await pumpSettings(tester, reminderScheduler: scheduler);

    await tapLabel(tester, 'Sleep reminder');

    expect(tester.widget<M3ESwitch>(find.byType(M3ESwitch)).value, isFalse);
    expect(scheduler.scheduled, isEmpty);
    expect(store.reminderSaves, isEmpty);
    expect(
      find.text('Allow notifications to get the sleep reminder.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();

    expect(scheduler.openSettingsCalls, 1);
  });

  testWidgets('shows a warning when Android blocks notifications', (
    tester,
  ) async {
    final scheduler = FakeSleepReminderScheduler(
      notificationsAreEnabled: false,
    );
    await pumpSettings(
      tester,
      initialReminder: const SleepReminder(enabled: true, hour: 22, minute: 0),
      reminderScheduler: scheduler,
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsScreen)),
    );
    await container
        .read(sleepReminderControllerProvider.notifier)
        .sync(isSleeping: false);
    await tester.pumpAndSettle();

    expect(find.text('Notifications are off'), findsOneWidget);
    expect(
      find.text('Allow Sleepy3 to send the notification.'),
      findsOneWidget,
    );
  });

  testWidgets('reminder details fit at 200% text in Spanish', (tester) async {
    final scheduler = FakeSleepReminderScheduler(
      notificationsAreEnabled: false,
    );
    await pumpSettings(
      tester,
      initialLanguage: AppLanguage.spanish,
      initialReminder: const SleepReminder(enabled: true, hour: 22, minute: 0),
      reminderScheduler: scheduler,
      textScale: 2,
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsScreen)),
    );
    await container
        .read(sleepReminderControllerProvider.notifier)
        .sync(isSleeping: false);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    for (final finder in [
      find.text('Aviso de sueño'),
      find.textContaining('Todos los días'),
      find.text('Hora del recordatorio'),
      find.textContaining('10:00'),
      find.text('Las notificaciones están desactivadas'),
      find.text('Permite que Sleepy3 envíe la notificación.'),
    ]) {
      final paragraph = tester.renderObject<RenderParagraph>(finder.first);
      expect(paragraph.didExceedMaxLines, isFalse, reason: finder.toString());
    }
  });

  testWidgets('the reminder time row opens the time picker', (tester) async {
    await pumpSettings(
      tester,
      initialReminder: const SleepReminder(enabled: true, hour: 22, minute: 0),
    );

    await tapLabel(tester, 'Reminder time');

    expect(find.text('OK'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('opens the source dialog with Local and Google Health', (
    tester,
  ) async {
    await pumpSettings(tester);

    await tapLabel(tester, 'Source');

    expect(find.text('Sleep data source'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
    expect(find.text('Local'), findsNWidgets(2));
    expect(find.text('Google Health'), findsNWidgets(2));

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Sleep data source'), findsNothing);
    expect(find.text('Local'), findsOneWidget);
    expect(find.text('On-device only.'), findsOneWidget);
  });

  testWidgets('switching to Google Health requests permissions and saves', (
    tester,
  ) async {
    final gateway = FakeHealthConnectGateway(
      readPermission: false,
      writePermission: false,
      grantReadOnRequest: true,
      grantWriteOnRequest: true,
    );
    final store = await pumpSettings(tester, gateway: gateway);

    await chooseSource(tester, 'Google Health');

    expect(gateway.permissionRequestCalls, 1);
    expect(store.sourceSaves, [SleepDataSource.healthConnect]);
    expect(
      find.descendant(
        of: find.byType(M3EListItem),
        matching: find.text('Google Health'),
      ),
      findsOneWidget,
    );

    await scrollToLabel(tester, 'Connected');
    expect(find.text('Connected'), findsOneWidget);

    await scrollToLabel(
      tester,
      'Stored in Health Connect. Google Health can read it.',
    );
    expect(
      find.text('Stored in Health Connect. Google Health can read it.'),
      findsOneWidget,
    );
  });

  testWidgets('a denied permission keeps Local and explains why', (
    tester,
  ) async {
    final gateway = FakeHealthConnectGateway(
      readPermission: false,
      writePermission: false,
      grantReadOnRequest: false,
      grantWriteOnRequest: false,
    );
    final store = await pumpSettings(tester, gateway: gateway);

    await chooseSource(tester, 'Google Health');

    expect(store.sourceSaves, isEmpty);
    expect(find.text('Local'), findsOneWidget);
    await scrollToLabel(tester, 'On-device only.');
    expect(find.text('On-device only.'), findsOneWidget);
    expect(
      find.text('Google Health needs permission to read and write sleep.'),
      findsOneWidget,
    );
  });

  testWidgets('reports an unavailable Health Connect', (tester) async {
    final store = await pumpSettings(
      tester,
      gateway: FakeHealthConnectGateway(
        availability: HealthConnectAvailability.unavailable,
      ),
    );

    await chooseSource(tester, 'Google Health');

    expect(store.sourceSaves, isEmpty);
    expect(find.text('Local'), findsOneWidget);
    expect(
      find.text('Google Health is not available on this device.'),
      findsOneWidget,
    );
  });

  testWidgets('reports a Health Connect update that is required', (
    tester,
  ) async {
    final store = await pumpSettings(
      tester,
      gateway: FakeHealthConnectGateway(
        availability: HealthConnectAvailability.updateRequired,
      ),
    );

    await chooseSource(tester, 'Google Health');

    expect(store.sourceSaves, isEmpty);
    expect(find.text('Local'), findsOneWidget);
    expect(
      find.text('Update Health Connect to use Google Health.'),
      findsOneWidget,
    );
  });

  testWidgets('a failed save keeps the previous source', (tester) async {
    final store = FakeSettingsStore(failWrites: true);
    await pumpSettings(tester, store: store);

    await chooseSource(tester, 'Google Health');

    expect(store.sourceSaves, isEmpty);
    expect(find.text('Local'), findsOneWidget);
    expect(find.text("Couldn't save the sleep data source."), findsOneWidget);
  });

  testWidgets('switching back to Local does not revoke permissions', (
    tester,
  ) async {
    final gateway = FakeHealthConnectGateway(
      readPermission: true,
      writePermission: true,
    );
    final store = await pumpSettings(
      tester,
      source: SleepDataSource.healthConnect,
      gateway: gateway,
    );

    await scrollToLabel(
      tester,
      'Stored in Health Connect. Google Health can read it.',
    );
    expect(
      find.text('Stored in Health Connect. Google Health can read it.'),
      findsOneWidget,
    );

    await scrollToLabel(tester, 'Source', delta: -160);
    await chooseSource(tester, 'Local');

    expect(store.sourceSaves, [SleepDataSource.local]);
    expect(gateway.readPermission, isTrue);
    expect(gateway.writePermission, isTrue);
    expect(find.text('Local'), findsOneWidget);
    expect(find.text('Google Health'), findsOneWidget);

    await scrollToLabel(tester, 'On-device only.');
    expect(find.text('On-device only.'), findsOneWidget);
  });

  testWidgets('shows the connected status and the pending uploads', (
    tester,
  ) async {
    final session = SleepSession(
      startedAt: DateTime(2026, 10, 20, 22),
      endedAt: DateTime(2026, 10, 21, 6),
    );

    await pumpSettings(
      tester,
      source: SleepDataSource.healthConnect,
      healthSyncStore: FakeHealthSyncStore()..addLocal(session),
    );

    expect(find.text('Connected · 1 pending'), findsOneWidget);
  });

  testWidgets('downloads every Health Connect session into the local copy', (
    tester,
  ) async {
    final session = HealthSleepSession(
      uuid: 'record-1',
      startedAt: DateTime(2026, 10, 20, 22),
      endedAt: DateTime(2026, 10, 21, 6),
    );
    final healthSyncStore = FakeHealthSyncStore();

    await pumpSettings(
      tester,
      gateway: FakeHealthConnectGateway(sessions: [session]),
      healthSyncStore: healthSyncStore,
    );

    await tapLabel(tester, 'Import');

    expect(find.text('Download from Google Health?'), findsOneWidget);
    expect(
      find.textContaining('Local sessions are not changed.'),
      findsOneWidget,
    );

    await tapDialogLabel(tester, 'Download all');

    expect(find.text('Download complete'), findsOneWidget);
    expect(find.text('1 session added'), findsOneWidget);
    expect(healthSyncStore.rows, hasLength(1));
    expect(healthSyncStore.rows.single.healthRecordId, 'record-1');

    await tapLabel(tester, 'Close');
    expect(find.text('Download complete'), findsNothing);
  });

  testWidgets('a download without history access copies the last 30 days', (
    tester,
  ) async {
    final recent = HealthSleepSession(
      uuid: 'recent',
      startedAt: DateTime(2026, 10, 20, 22),
      endedAt: DateTime(2026, 10, 21, 6),
    );
    final old = HealthSleepSession(
      uuid: 'old',
      startedAt: DateTime(2026, 8, 1, 22),
      endedAt: DateTime(2026, 8, 2, 6),
    );
    final gateway = FakeHealthConnectGateway(
      sessions: [recent, old],
      historyPermission: false,
      grantHistoryOnRequest: false,
    );
    final healthSyncStore = FakeHealthSyncStore();

    await pumpSettings(
      tester,
      gateway: gateway,
      healthSyncStore: healthSyncStore,
    );

    await tapLabel(tester, 'Import');
    expect(
      find.textContaining('without it, only the last 30 days'),
      findsOneWidget,
    );
    await tapDialogLabel(tester, 'Download all');

    expect(find.text('Download complete'), findsOneWidget);
    expect(find.textContaining('1 session added'), findsOneWidget);
    expect(
      find.textContaining('Only the last 30 days were downloaded.'),
      findsOneWidget,
    );
    expect(gateway.historyPermissionRequestCalls, 1);
    expect(healthSyncStore.rows.single.healthRecordId, 'recent');
  });

  testWidgets('sync last uploads only the newest pending session', (
    tester,
  ) async {
    final older = SleepSession(
      startedAt: DateTime(2026, 10, 18, 22),
      endedAt: DateTime(2026, 10, 19, 6),
    );
    final newer = SleepSession(
      startedAt: DateTime(2026, 10, 19, 22),
      endedAt: DateTime(2026, 10, 20, 6),
    );
    final gateway = FakeHealthConnectGateway();
    final healthSyncStore = FakeHealthSyncStore()
      ..addLocal(older)
      ..addLocal(newer);

    await pumpSettings(
      tester,
      gateway: gateway,
      healthSyncStore: healthSyncStore,
    );

    await tapLabel(tester, 'Sync');
    expect(find.text('Sync last session?'), findsOneWidget);

    await tapDialogLabel(tester, 'Sync');

    expect(find.text('Sync complete'), findsOneWidget);
    expect(find.text('1 session sent to Google Health'), findsOneWidget);
    expect(gateway.writes.single.startedAt, newer.startedAt);
    expect(
      healthSyncStore.rows.where((row) => row.isPendingUpload),
      hasLength(1),
    );

    await tapLabel(tester, 'Close');
  });

  testWidgets('add all warns about sessions added manually', (tester) async {
    await pumpSettings(tester);

    await tapLabel(tester, 'Add');

    expect(find.text('Add all previous sessions?'), findsOneWidget);
    expect(find.textContaining('may appear twice'), findsOneWidget);

    await tapDialogLabel(tester, 'Cancel');
  });

  testWidgets('a denied read permission explains the download failure', (
    tester,
  ) async {
    await pumpSettings(
      tester,
      gateway: FakeHealthConnectGateway(
        readPermission: false,
        grantReadOnRequest: false,
      ),
    );

    await tapLabel(tester, 'Import');
    await tapDialogLabel(tester, 'Download all');

    expect(find.text("Couldn't download"), findsOneWidget);
    expect(
      find.text('Google Health needs permission to read sleep.'),
      findsOneWidget,
    );

    await tapLabel(tester, 'Close');
  });

  testWidgets(
    'the first switch to Google Health offers to copy local sessions',
    (tester) async {
      final session = SleepSession(
        startedAt: DateTime(2026, 10, 20, 22),
        endedAt: DateTime(2026, 10, 21, 6),
      );
      final gateway = FakeHealthConnectGateway();
      final healthSyncStore = FakeHealthSyncStore()..addLocal(session);

      await pumpSettings(
        tester,
        gateway: gateway,
        healthSyncStore: healthSyncStore,
      );

      await chooseSource(tester, 'Google Health');

      expect(find.text('Copy local sessions?'), findsOneWidget);
      expect(
        find.text('1 local session is not in Google Health yet.'),
        findsOneWidget,
      );

      await tapDialogLabel(tester, 'Sync');

      expect(find.text('Sync complete'), findsOneWidget);
      expect(find.text('1 session sent to Google Health'), findsOneWidget);
      expect(gateway.writes, hasLength(1));

      await tapLabel(tester, 'Close');
    },
  );

  testWidgets('switching with no local history does not prompt', (
    tester,
  ) async {
    await pumpSettings(tester);

    await chooseSource(tester, 'Google Health');

    expect(find.text('Copy local sessions?'), findsNothing);
    expect(find.text('Connected'), findsOneWidget);
  });

  testWidgets('Connect requests permissions again after a revoke', (
    tester,
  ) async {
    final gateway = FakeHealthConnectGateway(
      readPermission: false,
      writePermission: false,
      grantReadOnRequest: true,
      grantWriteOnRequest: true,
    );

    await pumpSettings(
      tester,
      source: SleepDataSource.healthConnect,
      gateway: gateway,
    );

    expect(find.text('Permission needed'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);

    await tapLabel(tester, 'Connect');

    expect(gateway.permissionRequestCalls, 1);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('Connect'), findsNothing);
  });

  testWidgets('Install opens the store when Health Connect is missing', (
    tester,
  ) async {
    final gateway = FakeHealthConnectGateway(
      availability: HealthConnectAvailability.unavailable,
    );

    await pumpSettings(
      tester,
      source: SleepDataSource.healthConnect,
      gateway: gateway,
    );

    expect(find.text('Not available'), findsOneWidget);
    expect(find.text('Install'), findsOneWidget);

    await tapLabel(tester, 'Install');

    expect(gateway.installCalls, 1);
  });

  testWidgets('asks to install an update when Health Connect is outdated', (
    tester,
  ) async {
    await pumpSettings(
      tester,
      source: SleepDataSource.healthConnect,
      gateway: FakeHealthConnectGateway(
        availability: HealthConnectAvailability.updateRequired,
      ),
    );

    expect(find.text('Update required'), findsOneWidget);
    expect(find.text('Install'), findsOneWidget);
  });

  testWidgets('Google Health status fits at 200% text', (tester) async {
    await pumpSettings(
      tester,
      source: SleepDataSource.healthConnect,
      gateway: FakeHealthConnectGateway(
        readPermission: false,
        writePermission: false,
      ),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);

    await scrollToLabel(tester, 'Status');
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Permission needed'), findsOneWidget);

    await scrollToLabel(tester, 'Connect');
    expect(find.text('Connect'), findsOneWidget);

    for (final label in ['Status', 'Permission needed', 'Connect']) {
      var finder = find.text(label);
      if (finder.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          finder,
          160,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
      }
      finder = find.text(label).last;
      final paragraph = tester.renderObject<RenderParagraph>(finder);
      expect(
        paragraph.didExceedMaxLines,
        isFalse,
        reason: '$label is truncated at 200% text',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('applying a theme updates the row and saves it', (tester) async {
    final store = await pumpSettings(tester);

    await tapLabel(tester, 'Theme');

    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
    expect(find.text('System'), findsNWidgets(2));
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);

    await tapLabel(tester, 'Dark');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(store.saves, [AppThemeMode.dark]);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('System'), findsNothing);
  });

  testWidgets('cancelling the theme dialog changes nothing', (tester) async {
    final store = await pumpSettings(tester);

    await tapLabel(tester, 'Theme');
    await tapLabel(tester, 'Light');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(store.saves, isEmpty);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsNothing);
  });

  testWidgets('applying a time format updates the row and saves it', (
    tester,
  ) async {
    final store = await pumpSettings(tester);

    await tapLabel(tester, 'Time format');

    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
    expect(find.text('12-hour'), findsNWidgets(2));
    expect(find.text('24-hour'), findsOneWidget);

    await tapDialogLabel(tester, '24-hour');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(store.timeFormatSaves, [AppTimeFormat.twentyFourHour]);
    expect(find.text('24-hour'), findsOneWidget);
    expect(find.text('12-hour'), findsNothing);
  });

  testWidgets('cancelling the time format dialog changes nothing', (
    tester,
  ) async {
    final store = await pumpSettings(tester);

    await tapLabel(tester, 'Time format');
    await tapDialogLabel(tester, '24-hour');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(store.timeFormatSaves, isEmpty);
    expect(find.text('12-hour'), findsOneWidget);
    expect(find.text('24-hour'), findsNothing);
  });

  testWidgets('shows the saved 24-hour format', (tester) async {
    await pumpSettings(tester, initialTimeFormat: AppTimeFormat.twentyFourHour);

    expect(find.text('24-hour'), findsOneWidget);
    expect(find.text('12-hour'), findsNothing);
  });

  testWidgets('language dialog offers only English and Español', (
    tester,
  ) async {
    await pumpSettings(tester);

    await tapLabel(tester, 'Language');

    expect(find.text('English'), findsNWidgets(2));
    expect(find.text('Español'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Español'), findsNothing);
  });

  testWidgets('applying a language updates the screen and saves it', (
    tester,
  ) async {
    final store = await pumpSettings(tester);

    await tapLabel(tester, 'Language');
    await tapLabel(tester, 'Español');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(store.languageSaves, [AppLanguage.spanish]);
    expect(find.text('Apariencia'), findsOneWidget);
    expect(find.text('Idioma'), findsOneWidget);
    expect(find.text('Español'), findsOneWidget);
    expect(find.text('English'), findsNothing);
  });

  testWidgets('Spanish settings fit at 200% text', (tester) async {
    await pumpSettings(
      tester,
      initialLanguage: AppLanguage.spanish,
      version: const AppVersion(version: '0.1.0', buildNumber: '1'),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);

    for (final label in [
      'Ajustes',
      'Apariencia',
      'Tema',
      'Sistema',
      'Formato de hora',
      '12 horas',
      'Idioma',
      'Español',
      'Recordatorios',
      'Aviso de sueño',
      'Desactivado',
      'Datos de sueño',
      'Fuente',
      'Local',
      'Importar',
      'Google Health',
      'Estado',
      'Sincronizar',
      'Añadir',
      'Acerca de',
      'Privacidad',
      'Solo en este dispositivo.',
      'Versión',
      '0.1.0 (1)',
      'Licencias',
    ]) {
      final finder = find.text(label);
      if (finder.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          finder,
          160,
          scrollable: find.byType(Scrollable),
        );
        await tester.pumpAndSettle();
      }
      final paragraph = tester.renderObject<RenderParagraph>(finder);
      expect(
        paragraph.didExceedMaxLines,
        isFalse,
        reason: '$label is truncated at 200% text',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('hides the version row when the version is unknown', (
    tester,
  ) async {
    await pumpSettings(tester);

    expect(find.text('Version'), findsNothing);

    await scrollToLabel(tester, 'Licenses');
    expect(find.text('Licenses'), findsOneWidget);
  });

  testWidgets('announces the current theme, version and source', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    try {
      await pumpSettings(
        tester,
        version: const AppVersion(version: '0.1.0', buildNumber: '1'),
      );

      expect(find.bySemanticsLabel(RegExp('Theme, system')), findsOneWidget);

      await scrollToLabel(tester, 'Version');
      expect(find.bySemanticsLabel('Version, 0.1.0 (1)'), findsOneWidget);

      await scrollToLabel(tester, 'Source', delta: -160);
      expect(find.bySemanticsLabel(RegExp('Source')), findsOneWidget);
    } finally {
      handle.dispose();
    }
  });

  testWidgets('theme dialog fits at 200% text', (tester) async {
    await pumpSettings(tester, textScale: 2);

    await tapLabel(tester, 'Theme');

    expect(tester.takeException(), isNull);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
    for (final label in ['System', 'Light', 'Dark']) {
      final paragraph = tester.renderObject<RenderParagraph>(
        find.text(label).last,
      );
      expect(paragraph.didExceedMaxLines, isFalse);
    }
  });

  testWidgets('opens the license page', (tester) async {
    await pumpSettings(
      tester,
      version: const AppVersion(version: '0.1.0', buildNumber: '1'),
    );

    await tapLabel(tester, 'Licenses');

    expect(find.byType(LicensePage), findsOneWidget);
    expect(find.text('GNU General Public License v3.0'), findsOneWidget);
  });

  testWidgets('fits at 360dp and 200% text', (tester) async {
    await pumpSettings(
      tester,
      version: const AppVersion(version: '0.1.0', buildNumber: '1'),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);

    for (final label in [
      'Settings',
      'Appearance',
      'Theme',
      'System',
      'Language',
      'English',
      'Reminders',
      'Sleep reminder',
      'Off',
      'Sleep data',
      'Source',
      'Local',
      'Import',
      'Google Health',
      'Status',
      'Sync',
      'Add',
      'About',
      'Privacy',
      'On-device only.',
      'Version',
      '0.1.0 (1)',
      'Licenses',
    ]) {
      final finder = find.text(label);
      if (finder.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          finder,
          160,
          scrollable: find.byType(Scrollable),
        );
        await tester.pumpAndSettle();
      }
      final paragraph = tester.renderObject<RenderParagraph>(finder);
      expect(
        paragraph.didExceedMaxLines,
        isFalse,
        reason: '$label is truncated at 200% text',
      );
    }
    expect(tester.takeException(), isNull);
  });
}
