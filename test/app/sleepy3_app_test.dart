import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sleepy3/app/sleepy3_app.dart';
import 'package:sleepy3/app/sleepy3_shell.dart';
import 'package:sleepy3/core/theme/sleepy3_theme.dart';
import 'package:sleepy3/features/settings/application/theme_mode_controller.dart';
import 'package:sleepy3/features/settings/domain/app_theme_mode.dart';
import 'package:sleepy3/features/sleep_tracking/application/sleep_tracking_controller.dart';

import '../features/settings/fakes.dart';
import '../features/sleep_tracking/fakes.dart';

void main() {
  Future<FakeSettingsStore> pumpApp(
    WidgetTester tester, {
    required AppThemeMode mode,
    required Brightness platformBrightness,
  }) async {
    tester.view.physicalSize = const Size(360, 800) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    tester.platformDispatcher.platformBrightnessTestValue = platformBrightness;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    final settingsStore = FakeSettingsStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sleepClockProvider.overrideWithValue(
            () => DateTime(2026, 10, 20, 22, 30),
          ),
          sleepSessionStoreProvider.overrideWithValue(FakeSleepSessionStore()),
          settingsStoreProvider.overrideWithValue(settingsStore),
          initialThemeModeProvider.overrideWithValue(mode),
        ],
        child: const Sleepy3App(),
      ),
    );
    await tester.pumpAndSettle();
    return settingsStore;
  }

  Brightness appBrightness(WidgetTester tester) {
    final context = tester.element(find.byType(Sleepy3Shell));
    return Theme.of(context).brightness;
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

  testWidgets('uses the seeded light and dark schemes', (tester) async {
    await pumpApp(
      tester,
      mode: AppThemeMode.light,
      platformBrightness: Brightness.dark,
    );

    var context = tester.element(find.byType(Sleepy3Shell));
    var theme = M3ETheme.of(context);
    expect(theme.brightness, Brightness.light);
    expect(theme.colorScheme.primary, Sleepy3Theme.light().colorScheme.primary);
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
    expect(theme.colorScheme.primary, Sleepy3Theme.dark().colorScheme.primary);
    expect(
      theme.colorScheme.primary,
      isNot(Sleepy3Theme.light().colorScheme.primary),
    );
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
}
