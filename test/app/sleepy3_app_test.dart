import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sleepy3/app/sleepy3_app.dart';
import 'package:sleepy3/core/theme/sleepy3_theme.dart';
import 'package:sleepy3/features/sleep_tracking/application/sleep_tracking_controller.dart';

import '../features/sleep_tracking/fakes.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, Brightness brightness) async {
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sleepClockProvider.overrideWithValue(
            () => DateTime(2026, 10, 20, 22, 30),
          ),
          sleepSessionStoreProvider.overrideWithValue(FakeSleepSessionStore()),
        ],
        child: const Sleepy3App(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('starts in the light scheme', (tester) async {
    await pumpApp(tester, Brightness.light);

    expect(find.text('Sleepy3'), findsOneWidget);
    final context = tester.element(find.text('Sleepy3'));
    final theme = M3ETheme.of(context);

    expect(theme.brightness, Brightness.light);
    expect(theme.colorScheme.primary, Sleepy3Theme.light().colorScheme.primary);
    expect(
      theme.typography.baseline.bodyMedium.fontFamily,
      Sleepy3Theme.fontFamily,
    );
  });

  testWidgets('follows the system into the seeded dark scheme', (tester) async {
    await pumpApp(tester, Brightness.light);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();

    final context = tester.element(find.text('Sleepy3'));
    final theme = M3ETheme.of(context);

    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.primary, Sleepy3Theme.dark().colorScheme.primary);
    expect(
      theme.colorScheme.primary,
      isNot(Sleepy3Theme.light().colorScheme.primary),
    );
  });
}
