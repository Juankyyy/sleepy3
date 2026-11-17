import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_goal.dart';

void main() {
  group('sleep goal', () {
    test('offers 6 to 10 hours in 30-minute steps', () {
      expect(sleepGoalOptions, hasLength(9));
      expect(sleepGoalOptions.first, minimumSleepGoal);
      expect(sleepGoalOptions.last, maximumSleepGoal);
      expect(sleepGoalOptions, contains(defaultSleepGoal));
      expect(
        sleepGoalOptions.every(
          (goal) => goal.inMinutes % sleepGoalStep.inMinutes == 0,
        ),
        isTrue,
      );
    });

    test('accepts only the goals the picker offers', () {
      expect(isSelectableSleepGoal(defaultSleepGoal), isTrue);
      expect(isSelectableSleepGoal(const Duration(hours: 6)), isTrue);
      expect(
        isSelectableSleepGoal(const Duration(hours: 6, minutes: 30)),
        isTrue,
      );
      expect(isSelectableSleepGoal(const Duration(hours: 10)), isTrue);
      expect(
        isSelectableSleepGoal(const Duration(hours: 5, minutes: 59)),
        isFalse,
      );
      expect(
        isSelectableSleepGoal(const Duration(hours: 10, minutes: 30)),
        isFalse,
      );
      expect(
        isSelectableSleepGoal(const Duration(hours: 8, minutes: 15)),
        isFalse,
      );
    });

    test('reads six, eight and ten hours from the stored minutes', () {
      expect(parseSleepGoalMinutes('360'), const Duration(hours: 6));
      expect(parseSleepGoalMinutes('480'), const Duration(hours: 8));
      expect(parseSleepGoalMinutes('600'), const Duration(hours: 10));
    });

    test('falls back to eight hours for a missing or malformed value', () {
      expect(parseSleepGoalMinutes(null), defaultSleepGoal);
      expect(parseSleepGoalMinutes(''), defaultSleepGoal);
      expect(parseSleepGoalMinutes('eight'), defaultSleepGoal);
      expect(parseSleepGoalMinutes('470'), defaultSleepGoal);
      expect(parseSleepGoalMinutes('300'), defaultSleepGoal);
      expect(parseSleepGoalMinutes('720'), defaultSleepGoal);
    });
  });
}
