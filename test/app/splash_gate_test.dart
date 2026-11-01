import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sleepy3/app/splash_gate.dart';

void main() {
  testWidgets('shows the mark over the child and then fades away', (
    tester,
  ) async {
    var finished = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SplashGate(
          startSignal: Future<void>.value(),
          onFinished: () => finished++,
          child: const Text('shell'),
        ),
      ),
    );

    expect(find.byKey(const Key('sleepy3-splash')), findsOneWidget);
    expect(find.text('shell'), findsOneWidget);
    expect(finished, 0);

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('sleepy3-splash')), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sleepy3-splash')), findsNothing);
    expect(find.text('shell'), findsOneWidget);
    expect(finished, 1);
  });

  testWidgets('skips the splash when animations are disabled', (tester) async {
    var finished = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: SplashGate(
            startSignal: Future<void>.value(),
            onFinished: () => finished++,
            child: const Text('shell'),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('sleepy3-splash')), findsNothing);
    expect(find.text('shell'), findsOneWidget);
    expect(finished, 1);
  });
}
