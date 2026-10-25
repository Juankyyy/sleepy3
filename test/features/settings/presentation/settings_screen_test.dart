import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sleepy3/core/theme/sleepy3_theme.dart';
import 'package:sleepy3/features/settings/application/app_version_provider.dart';
import 'package:sleepy3/features/settings/application/theme_mode_controller.dart';
import 'package:sleepy3/features/settings/domain/app_theme_mode.dart';
import 'package:sleepy3/features/settings/domain/app_version.dart';
import 'package:sleepy3/features/settings/presentation/settings_screen.dart';

import '../fakes.dart';

void main() {
  Future<FakeSettingsStore> pumpSettings(
    WidgetTester tester, {
    AppThemeMode initial = AppThemeMode.system,
    AppVersion? version,
    FakeSettingsStore? store,
    double textScale = 1,
    Size size = const Size(360, 800),
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final settingsStore = store ?? FakeSettingsStore();
    final data = Sleepy3Theme.light();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsStoreProvider.overrideWithValue(settingsStore),
          initialThemeModeProvider.overrideWithValue(initial),
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

  testWidgets('shows appearance, Health Connect and about sections', (
    tester,
  ) async {
    await pumpSettings(
      tester,
      version: const AppVersion(version: '0.1.0', buildNumber: '1'),
    );

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Theme, Health Connect and app info.'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Health Connect'), findsOneWidget);
    expect(find.text('Sleep'), findsOneWidget);
    expect(find.text('Coming soon.'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('On-device only.'), findsOneWidget);
    expect(find.text('Version'), findsOneWidget);
    expect(find.text('0.1.0 (1)'), findsOneWidget);
    expect(find.text('Licenses'), findsOneWidget);

    expect(find.byType(M3EList), findsNWidgets(4));
    expect(find.byType(M3EListItem), findsNWidgets(5));
  });

  testWidgets('Health Connect is informational and disabled', (tester) async {
    await pumpSettings(tester);

    final row = tester.widget<M3EListItem>(
      find.widgetWithText(M3EListItem, 'Sleep'),
    );
    expect(row.enabled, isFalse);
    expect(row.onTap, isNull);
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

  testWidgets('announces the current theme, version and disabled sync row', (
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
      expect(
        find.bySemanticsLabel(RegExp('Sleep, coming soon')),
        findsOneWidget,
      );
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
      'Health Connect',
      'Sleep',
      'Coming soon.',
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
