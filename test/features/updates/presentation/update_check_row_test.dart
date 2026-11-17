import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sleepy3/core/theme/sleepy3_theme.dart';
import 'package:sleepy3/features/settings/application/app_version_provider.dart';
import 'package:sleepy3/features/settings/application/settings_providers.dart';
import 'package:sleepy3/features/settings/domain/app_version.dart';
import 'package:sleepy3/features/updates/application/app_update_controller.dart';
import 'package:sleepy3/features/updates/domain/app_release.dart';
import 'package:sleepy3/features/updates/domain/update_prompt_preferences.dart';
import 'package:sleepy3/features/updates/presentation/widgets/update_check_row.dart';
import 'package:sleepy3/l10n/l10n.dart';

import '../../settings/fakes.dart';
import '../fakes.dart';

void main() {
  Future<FakeSettingsStore> pumpRow(
    WidgetTester tester, {
    required FakeAppReleaseGateway gateway,
    FakeUpdateLinkLauncher? launcher,
    AppVersion version = const AppVersion(version: '0.3.1'),
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

    final store = FakeSettingsStore(updatePromptPreferences: preferences);
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
        ],
        child: M3EMaterialApp(
          title: 'Sleepy3',
          data: data,
          theme: data.toThemeData(),
          locale: locale,
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: UpdateCheckRow(version: version),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets('starts idle and shows the latest version', (tester) async {
    await pumpRow(tester, gateway: FakeAppReleaseGateway.upToDate('0.3.1'));

    expect(find.text('Check for updates'), findsOneWidget);
    expect(find.text('See if a newer version is on GitHub.'), findsOneWidget);

    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();

    expect(find.text('Sleepy3 0.3.1 is the latest version.'), findsOneWidget);
  });

  testWidgets('shows a newer version and downloads its APK', (tester) async {
    final launcher = FakeUpdateLinkLauncher();
    final release = testRelease('0.4.0');
    final store = await pumpRow(
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

    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();

    expect(launcher.uris, [release.apkUrl]);
    expect(store.updatePromptPreferences.dismissedVersion, '0.4.0');
  });

  testWidgets('shows the checking state while the request is in flight', (
    tester,
  ) async {
    final gateway = FakeAppReleaseGateway()..pending = Completer<AppRelease>();
    await pumpRow(tester, gateway: gateway);

    await tester.tap(find.text('Check for updates'));
    await tester.pump();

    expect(find.text('Checking for updates…'), findsOneWidget);

    gateway.pending!.complete(testRelease('0.4.0'));
    await tester.pumpAndSettle();

    expect(
      find.text('Version 0.4.0 is available. Tap to download the APK.'),
      findsOneWidget,
    );
  });

  testWidgets('explains a failed check and retries', (tester) async {
    final gateway = FakeAppReleaseGateway()..error = StateError('offline');
    await pumpRow(tester, gateway: gateway);

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
    final store = await pumpRow(
      tester,
      gateway: FakeAppReleaseGateway(testRelease('0.4.0')),
      launcher: launcher,
    );

    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't open the link. Try again."), findsOneWidget);
    expect(store.updatePromptPreferences.dismissedVersion, isNull);
  });

  testWidgets('fits at 200% text and renders in Spanish', (tester) async {
    await pumpRow(
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

    await tester.tap(find.text('Buscar actualizaciones'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'La versión 0.4.0 está disponible. Toca para descargar el APK.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
