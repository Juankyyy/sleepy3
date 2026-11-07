import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sleepy3/core/theme/sleepy3_theme.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_goal.dart';
import 'package:sleepy3/features/stats/presentation/widgets/sleep_goal_mark.dart';

void main() {
  const belowGoal = Duration(hours: 7, minutes: 2);
  const belowGoalFraction = 422 / 480;

  Widget host(Widget child) {
    return M3ETheme(
      data: Sleepy3Theme.light(),
      child: MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: child),
        ),
      ),
    );
  }

  SleepGoalMark mark({
    required Duration duration,
    Animation<double>? rotation,
    bool animateProgress = false,
  }) {
    final scheme = Sleepy3Theme.light().colorScheme;
    return SleepGoalMark(
      duration: duration,
      size: 56,
      strokeWidth: 5,
      color: scheme.primary,
      onColor: scheme.onPrimary,
      trackColor: scheme.onPrimaryContainer.withValues(alpha: 0.18),
      rotation: rotation,
      animateProgress: animateProgress,
    );
  }

  M3EProgressIndicator ring(WidgetTester tester) {
    return tester.widget<M3EProgressIndicator>(
      find.byType(M3EProgressIndicator),
    );
  }

  testWidgets('turns only the clover when the goal is met', (tester) async {
    final turn = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(seconds: 8),
    );
    addTearDown(turn.dispose);
    turn.repeat();

    await tester.pumpWidget(
      host(
        mark(
          duration: dailySleepGoal + const Duration(minutes: 13),
          rotation: turn,
        ),
      ),
    );

    expect(find.byType(M3EShapeContainer), findsOneWidget);
    final turns = find.byType(RotationTransition);
    expect(turns, findsOneWidget);
    expect(
      find.descendant(
        of: turns,
        matching: find.byIcon(M3EIcons.bedtime_rounded),
      ),
      findsNothing,
    );

    final before = tester.widget<RotationTransition>(turns).turns.value;
    await tester.pump(const Duration(seconds: 2));
    final after = tester.widget<RotationTransition>(turns).turns.value;
    expect(after, isNot(before));

    turn.stop();
  });

  testWidgets('does not clip the clover while it turns', (tester) async {
    final turn = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(seconds: 8),
    );
    addTearDown(turn.dispose);
    turn.repeat();

    await tester.pumpWidget(
      host(
        mark(
          duration: dailySleepGoal + const Duration(minutes: 13),
          rotation: turn,
        ),
      ),
    );

    final stacks = find.descendant(
      of: find.byType(SleepGoalMark),
      matching: find.byType(Stack),
    );
    expect(stacks, findsOneWidget);
    expect(tester.widget<Stack>(stacks).clipBehavior, Clip.none);

    turn.stop();
  });

  testWidgets('never turns the below-goal ring', (tester) async {
    final turn = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(seconds: 8),
    );
    addTearDown(turn.dispose);

    await tester.pumpWidget(host(mark(duration: belowGoal, rotation: turn)));

    expect(find.byType(M3EShapeContainer), findsNothing);
    expect(find.byType(RotationTransition), findsNothing);
    expect(ring(tester).value, closeTo(belowGoalFraction, 0.001));
  });

  testWidgets('fills a below-goal ring from zero', (tester) async {
    await tester.pumpWidget(
      host(mark(duration: belowGoal, animateProgress: true)),
    );

    expect(ring(tester).value, 0);
    await tester.pump(const Duration(milliseconds: 300));
    expect(ring(tester).value, 0);
    await tester.pump(const Duration(milliseconds: 200));
    expect(ring(tester).value, inExclusiveRange(0, belowGoalFraction));
    await tester.pump(const Duration(milliseconds: 600));
    expect(ring(tester).value, closeTo(belowGoalFraction, 0.001));
  });

  testWidgets('keeps the history ring static on its first frame', (
    tester,
  ) async {
    await tester.pumpWidget(host(mark(duration: belowGoal)));

    expect(ring(tester).value, closeTo(belowGoalFraction, 0.001));
  });
}
