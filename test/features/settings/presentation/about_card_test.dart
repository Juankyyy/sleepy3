import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sleepy3/core/theme/sleepy3_theme.dart';
import 'package:sleepy3/features/health/application/sleep_data_source_controller.dart';
import 'package:sleepy3/features/health/domain/sleep_data_source.dart';
import 'package:sleepy3/features/settings/application/app_version_provider.dart';
import 'package:sleepy3/features/settings/application/settings_providers.dart';
import 'package:sleepy3/features/settings/domain/app_version.dart';
import 'package:sleepy3/features/settings/presentation/widgets/about_card.dart';
import 'package:sleepy3/features/sleep_tracking/application/sleep_tracking_providers.dart';
import 'package:sleepy3/features/updates/application/app_update_controller.dart';
import 'package:sleepy3/features/updates/domain/app_release.dart';
import 'package:sleepy3/features/updates/domain/update_prompt_preferences.dart';
import 'package:sleepy3/l10n/l10n.dart';

import '../fakes.dart';
import '../../updates/fakes.dart';

void main() {
  Future<FakeSettingsStore> pumpAbout(
    WidgetTester tester, {
    required FakeAppReleaseGateway gateway,
    FakeUpdateLinkLauncher? launcher,
    AppVersion? version = const AppVersion(version: '0.3.1', buildNumber: '1'),
    SleepDataSource source = SleepDataSource.local,
    UpdatePromptPreferences preferences = UpdatePromptPreferences.defaults,
    double textScale = 1,
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = const Size(360, 800) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final store = FakeSettingsStore(
      updatePromptPreferences: preferences,
      sleepDataSource: source,
    );
    final data = Sleepy3Theme.light();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appVersionProvider.overrideWithValue(version),
          appReleaseGatewayProvider.overrideWithValue(gateway),
          updateLinkLauncherProvider.overrideWithValue(
            launcher ?? FakeUpdateLinkLauncher(),
          ),
          settingsStoreProvider.overrideWithValue(store),
          initialUpdatePromptPreferencesProvider.overrideWithValue(preferences),
          initialSleepDataSourceProvider.overrideWithValue(source),
          sleepClockProvider.overrideWithValue(
            () => DateTime(2026, 11, 17, 22),
          ),
        ],
        child: M3EMaterialApp(
          title: 'Sleepy3',
          data: data,
          theme: data.toThemeData(),
          locale: locale,
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: AboutCard(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets('shows the version without the build number', (tester) async {
    await pumpAbout(tester, gateway: FakeAppReleaseGateway.upToDate('0.3.1'));

    expect(find.text('Sleepy3'), findsOneWidget);
    expect(find.text('Version 0.3.1'), findsOneWidget);
    expect(find.text('0.3.1 (1)'), findsNothing);
    expect(find.text('Check for updates'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('settings-about-repository')),
      findsOneWidget,
    );
    expect(find.text('Licenses'), findsOneWidget);
    expect(find.text('On-device only.'), findsOneWidget);
  });

  testWidgets('checks for updates and reports the latest version', (
    tester,
  ) async {
    await pumpAbout(tester, gateway: FakeAppReleaseGateway.upToDate('0.3.1'));

    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();

    expect(find.text('Sleepy3 0.3.1 is the latest version.'), findsOneWidget);
    expect(find.text('Check for updates'), findsOneWidget);
  });

  testWidgets('keeps the checking state for at least one second', (
    tester,
  ) async {
    await pumpAbout(
      tester,
      gateway: FakeAppReleaseGateway(testRelease('0.4.0')),
    );

    await tester.tap(find.text('Check for updates'));
    await tester.pump();
    expect(find.text('Checking…'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('Checking…'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text('Download'), findsOneWidget);
  });

  testWidgets('shows a newer version and downloads its APK', (tester) async {
    final launcher = FakeUpdateLinkLauncher();
    final release = testRelease('0.4.0');
    final store = await pumpAbout(
      tester,
      gateway: FakeAppReleaseGateway(release),
      launcher: launcher,
    );

    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();

    expect(
      find.text('Version 0.4.0 is available. Tap to download the APK.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('settings-about-update-check')),
      findsOneWidget,
    );
    expect(find.text('Download'), findsOneWidget);

    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();

    expect(launcher.uris, [release.apkUrl]);
    expect(store.updatePromptPreferences.dismissedVersion, '0.4.0');
  });

  testWidgets('checks again while a release is available', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final launcher = FakeUpdateLinkLauncher();
      final gateway = FakeAppReleaseGateway(testRelease('0.4.0'));
      await pumpAbout(tester, gateway: gateway, launcher: launcher);

      await tester.tap(find.text('Check for updates'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('settings-about-update-check')),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Check for updates'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('settings-about-update-check')),
      );
      await tester.pumpAndSettle();

      expect(gateway.calls, 2);
      expect(launcher.uris, isEmpty);
      expect(find.text('Download'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('shows the checking state while the request is in flight', (
    tester,
  ) async {
    final gateway = FakeAppReleaseGateway()..pending = Completer<AppRelease>();
    await pumpAbout(tester, gateway: gateway);

    await tester.tap(find.text('Check for updates'));
    await tester.pump();

    expect(find.text('Checking…'), findsOneWidget);
    expect(find.text('Checking for updates…'), findsOneWidget);

    gateway.pending!.complete(testRelease('0.4.0'));
    await tester.pumpAndSettle();

    expect(
      find.text('Version 0.4.0 is available. Tap to download the APK.'),
      findsOneWidget,
    );
    expect(find.text('Download'), findsOneWidget);
  });

  testWidgets('explains a failed check and retries', (tester) async {
    final gateway = FakeAppReleaseGateway()..error = StateError('offline');
    await pumpAbout(tester, gateway: gateway);

    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();

    expect(
      find.text("Couldn't check for updates. Tap to retry."),
      findsOneWidget,
    );

    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();

    expect(gateway.calls, 2);
  });

  testWidgets('shows a snackbar when the APK link cannot open', (tester) async {
    final launcher = FakeUpdateLinkLauncher(result: false);
    final store = await pumpAbout(
      tester,
      gateway: FakeAppReleaseGateway(testRelease('0.4.0')),
      launcher: launcher,
    );

    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't open the link. Try again."), findsOneWidget);
    expect(store.updatePromptPreferences.dismissedVersion, isNull);
  });

  testWidgets('opens the repository with the external launcher', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      final launcher = FakeUpdateLinkLauncher();
      await pumpAbout(
        tester,
        gateway: FakeAppReleaseGateway.upToDate('0.3.1'),
        launcher: launcher,
      );

      final button = find.byKey(const ValueKey('settings-about-repository'));
      expect(find.bySemanticsLabel('Open repository'), findsOneWidget);

      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(launcher.uris, [AboutCard.repositoryUri]);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('opens the license page', (tester) async {
    await pumpAbout(tester, gateway: FakeAppReleaseGateway.upToDate('0.3.1'));

    await tester.tap(find.text('Licenses'));
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
    expect(find.text('GNU General Public License v3.0'), findsOneWidget);
  });

  testWidgets('hides the version and update action when unknown', (
    tester,
  ) async {
    await pumpAbout(
      tester,
      version: null,
      gateway: FakeAppReleaseGateway.upToDate('0.3.1'),
    );

    expect(find.text('Version 0.3.1'), findsNothing);
    expect(find.text('Check for updates'), findsNothing);
    expect(find.text('Sleepy3'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('settings-about-repository')),
      findsOneWidget,
    );
    expect(find.text('Licenses'), findsOneWidget);
  });

  testWidgets('fits at 200% text in Spanish', (tester) async {
    await pumpAbout(
      tester,
      gateway: FakeAppReleaseGateway(testRelease('0.4.0')),
      textScale: 2,
      locale: const Locale('es'),
    );

    expect(find.text('Buscar actualizaciones'), findsOneWidget);
    expect(
      find.text('Comprueba si hay una versión más reciente en GitHub.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Buscar actualizaciones'));
    await tester.tap(find.text('Buscar actualizaciones'));
    await tester.pumpAndSettle();

    expect(find.text('Descargar'), findsOneWidget);
    expect(
      find.text(
        'La versión 0.4.0 está disponible. Toca para descargar el APK.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
