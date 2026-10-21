import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:sleepy3/app/sleepy3_app.dart';
import 'package:sleepy3/features/sleep_tracking/application/sleep_tracking_controller.dart';

void main() {
  testWidgets('the two actions drive the sleep state machine', (tester) async {
    var now = DateTime(2026, 10, 20, 22, 30);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sleepClockProvider.overrideWithValue(() => now)],
        child: const Sleepy3App(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Toca Dormir para empezar'), findsOneWidget);

    var buttons = tester.widgetList<M3EButton>(find.byType(M3EButton)).toList();
    expect(buttons, hasLength(2));
    expect(buttons[0].enabled, isTrue);
    expect(buttons[1].enabled, isFalse);

    await tester.tap(find.text('Dormir'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Durmiendo desde'), findsOneWidget);
    buttons = tester.widgetList<M3EButton>(find.byType(M3EButton)).toList();
    expect(buttons[0].enabled, isFalse);
    expect(buttons[1].enabled, isTrue);

    now = now.add(const Duration(hours: 7, minutes: 45));
    await tester.tap(find.text('Despertar'));
    await tester.pumpAndSettle();

    expect(find.text('Última sesión: 7h 45m'), findsOneWidget);
    buttons = tester.widgetList<M3EButton>(find.byType(M3EButton)).toList();
    expect(buttons[0].enabled, isTrue);
    expect(buttons[1].enabled, isFalse);
  });

  testWidgets('both action labels fit on a 360dp phone', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sleepClockProvider.overrideWithValue(
            () => DateTime(2026, 10, 20, 22, 30),
          ),
        ],
        child: const Sleepy3App(),
      ),
    );
    await tester.pumpAndSettle();

    for (final label in ['Dormir', 'Despertar']) {
      final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
      expect(
        paragraph.didExceedMaxLines,
        isFalse,
        reason: '$label is truncated at 360dp',
      );
    }
  });
}
