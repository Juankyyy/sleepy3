import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sleepy3/core/theme/sleepy3_theme.dart';
import 'package:sleepy3/features/health/application/health_connect_gateway_provider.dart';
import 'package:sleepy3/features/health/application/sleep_data_source_controller.dart';
import 'package:sleepy3/features/health/domain/health_connect_gateway.dart';
import 'package:sleepy3/features/health/domain/sleep_data_source.dart';
import 'package:sleepy3/features/settings/application/app_version_provider.dart';
import 'package:sleepy3/features/settings/application/theme_mode_controller.dart';
import 'package:sleepy3/features/settings/domain/app_theme_mode.dart';
import 'package:sleepy3/features/settings/domain/app_version.dart';
import 'package:sleepy3/features/settings/presentation/settings_screen.dart';

import '../../health/fakes.dart';
import '../fakes.dart';

void main() {
  Future<FakeSettingsStore> pumpSettings(
    WidgetTester tester, {
    AppThemeMode initial = AppThemeMode.system,
    SleepDataSource source = SleepDataSource.local,
    AppVersion? version,
    FakeSettingsStore? store,
    FakeHealthConnectGateway? gateway,
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
          initialSleepDataSourceProvider.overrideWithValue(source),
          healthConnectGatewayProvider.overrideWithValue(
            gateway ?? FakeHealthConnectGateway(),
          ),
          appVersionProvider.overrideWithValue(version),
        ],
        child: M3EMaterialApp(
          title: 'Sleepy3',
          data: data,
          theme: data.toThemeData(),
          locale: const Locale('en', 'US'),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('en', 'US')],
          home: const Scaffold(body: SettingsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return settingsStore;
  }

  // Labels sit inside the row's tappable surface, so the label itself is not
  // the hit target. Tapping its center still activates the row.
  Future<void> tapLabel(WidgetTester tester, String label) async {
    await tester.tap(find.text(label), warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  Future<void> chooseSource(WidgetTester tester, String label) async {
    await tapLabel(tester, 'Source');
    await tapLabel(tester, label);
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
    expect(find.text('Theme, sleep data and app info.'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Sleep data'), findsOneWidget);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Local'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('On-device only.'), findsOneWidget);
    expect(find.text('Version'), findsOneWidget);
    expect(find.text('0.1.0 (1)'), findsOneWidget);
    expect(find.text('Licenses'), findsOneWidget);

    expect(find.byType(M3EList), findsNWidgets(4));
    expect(find.byType(M3EListItem), findsNWidgets(5));
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
    expect(find.text('Google Health'), findsOneWidget);

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

    expect(
      find.text('Stored in Health Connect. Google Health can read it.'),
      findsOneWidget,
    );

    await chooseSource(tester, 'Local');

    expect(store.sourceSaves, [SleepDataSource.local]);
    expect(gateway.readPermission, isTrue);
    expect(gateway.writePermission, isTrue);
    expect(find.text('Local'), findsOneWidget);
    expect(find.text('On-device only.'), findsOneWidget);
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

  testWidgets('hides the version row when the version is unknown', (
    tester,
  ) async {
    await pumpSettings(tester);

    expect(find.text('Version'), findsNothing);
    expect(find.text('Licenses'), findsOneWidget);
    expect(find.byType(M3EListItem), findsNWidgets(4));
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
      expect(find.bySemanticsLabel('Version, 0.1.0 (1)'), findsOneWidget);
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
      'Sleep data',
      'Source',
      'Local',
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
