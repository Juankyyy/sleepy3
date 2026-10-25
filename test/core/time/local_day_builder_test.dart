import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/core/time/local_day_builder.dart';

void main() {
  Future<void> pumpDay(WidgetTester tester, DateTime Function() clock) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: LocalDayBuilder(
          clock: clock,
          builder: (context, day) =>
              Text('${day.year}-${day.month}-${day.day}'),
        ),
      ),
    );
  }

  testWidgets('shows the current local day', (tester) async {
    await pumpDay(tester, () => DateTime(2026, 10, 20, 22, 30));

    expect(find.text('2026-10-20'), findsOneWidget);
  });

  testWidgets('advances at local midnight', (tester) async {
    var now = DateTime(2026, 10, 20, 23, 59, 59);
    await pumpDay(tester, () => now);

    expect(find.text('2026-10-20'), findsOneWidget);

    now = DateTime(2026, 10, 21, 0, 0, 1);
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('2026-10-21'), findsOneWidget);
  });

  testWidgets('catches up when the app resumes on a new day', (tester) async {
    var now = DateTime(2026, 10, 20, 10);
    await pumpDay(tester, () => now);
    expect(find.text('2026-10-20'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );

    now = DateTime(2026, 10, 21, 9);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('2026-10-20'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.text('2026-10-21'), findsOneWidget);
  });

  testWidgets('cancels its timer when removed', (tester) async {
    await pumpDay(tester, () => DateTime(2026, 10, 20, 22, 30));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });
}
