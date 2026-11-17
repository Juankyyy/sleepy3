/// The nightly goal used by Home, Stats and the sleep notification.
///
/// Sleepy3's design decision, not an M3 token: the Home summary, the Stats
/// goal marks and the sleep notification all compare a night with the goal the
/// user chose in Settings.
const defaultSleepGoal = Duration(hours: 8);

/// The shortest goal the picker offers.
const minimumSleepGoal = Duration(hours: 6);

/// The longest goal the picker offers.
const maximumSleepGoal = Duration(hours: 10);

/// The distance between two goal options.
const sleepGoalStep = Duration(minutes: 30);

/// Every selectable goal, from [minimumSleepGoal] to [maximumSleepGoal] in
/// [sleepGoalStep] steps.
final List<Duration> sleepGoalOptions = List<Duration>.unmodifiable([
  for (
    var minutes = minimumSleepGoal.inMinutes;
    minutes <= maximumSleepGoal.inMinutes;
    minutes += sleepGoalStep.inMinutes
  )
    Duration(minutes: minutes),
]);

/// Whether [goal] is one of the options the picker offers.
bool isSelectableSleepGoal(Duration goal) =>
    goal >= minimumSleepGoal &&
    goal <= maximumSleepGoal &&
    goal.inMinutes % sleepGoalStep.inMinutes == 0;

/// Reads the goal stored in `preferences` as minutes.
///
/// A missing, malformed, out-of-range or off-step value falls back to
/// [defaultSleepGoal], so a corrupted preference never changes the goal used
/// by the rest of the app.
Duration parseSleepGoalMinutes(String? value) {
  final minutes = int.tryParse(value ?? '');
  if (minutes == null) return defaultSleepGoal;
  final goal = Duration(minutes: minutes);
  return isSelectableSleepGoal(goal) ? goal : defaultSleepGoal;
}
