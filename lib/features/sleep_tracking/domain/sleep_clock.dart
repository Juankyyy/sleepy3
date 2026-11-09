import 'dart:math' as math;

/// One day of wall-clock minutes, regardless of a DST transition.
const _minutesPerDay = 24 * 60;

/// Circular mean and spread of local clock times.
class SleepClockSummary {
  const SleepClockSummary({
    this.average,
    this.variability,
    this.earliest,
    this.latest,
  });

  /// Mean time since local midnight.
  final Duration? average;

  /// Circular standard deviation in minutes.
  final Duration? variability;

  /// Earliest time around [average], with midnight wrapping.
  final Duration? earliest;

  /// Latest time around [average], with midnight wrapping.
  final Duration? latest;
}

/// Circular mean and spread of local clock times.
///
/// Times are minutes since local midnight. Summer time does not affect this:
/// only the wall-clock hour is used. Results are rounded to the nearest minute
/// because the UI shows minutes.
SleepClockSummary summarizeSleepClockTimes(Iterable<DateTime> times) {
  final minutes = <double>[
    for (final time in times) _minutesSinceMidnight(time),
  ];
  if (minutes.isEmpty) return const SleepClockSummary();

  final mean = _circularMeanMinutes(minutes);
  final meanRounded = mean.round() % _minutesPerDay;
  final average = Duration(minutes: _wrapMinutes(meanRounded));
  final variability = minutes.length < 2
      ? null
      : Duration(
          minutes: _wrapMinutes(_circularDeviationMinutes(minutes).round()),
        );

  double? earliestOffset;
  double? latestOffset;
  for (final minute in minutes) {
    final offset = _signedOffset(minute, meanRounded.toDouble());
    if (earliestOffset == null || offset < earliestOffset) {
      earliestOffset = offset;
    }
    if (latestOffset == null || offset > latestOffset) latestOffset = offset;
  }

  final earliest = earliestOffset == null
      ? null
      : Duration(minutes: _wrapMinutes(meanRounded + earliestOffset.round()));
  final latest = latestOffset == null
      ? null
      : Duration(minutes: _wrapMinutes(meanRounded + latestOffset.round()));

  return SleepClockSummary(
    average: average,
    variability: variability,
    earliest: earliest,
    latest: latest,
  );
}

/// The wall-clock minute of [time], from 0 to 1439.
int sleepClockMinuteOfDay(DateTime time) {
  final local = time.toLocal();
  return local.hour * 60 + local.minute;
}

/// Signed minutes from [mean] to [minute], taking the shorter way around
/// midnight.
///
/// Positive is later on the clock. For example, 00:10 versus a mean of 23:50
/// returns 20, not 1420.
int signedClockOffsetMinutes(int minute, int mean) {
  final offset = (minute - mean) % _minutesPerDay;
  return offset > _minutesPerDay / 2 ? offset - _minutesPerDay : offset;
}

double _minutesSinceMidnight(DateTime time) {
  final local = time.toLocal();
  return local.hour * 60 +
      local.minute +
      local.second / 60 +
      local.millisecond / 60000;
}

double _circularMeanMinutes(List<double> minutes) {
  var sinSum = 0.0;
  var cosSum = 0.0;
  for (final minute in minutes) {
    final angle = 2 * math.pi * minute / _minutesPerDay;
    sinSum += math.sin(angle);
    cosSum += math.cos(angle);
  }

  final angle = math.atan2(sinSum, cosSum);
  return _wrapMinutesDouble(angle * _minutesPerDay / (2 * math.pi));
}

/// Circular standard deviation: `sqrt(-2 ln R)` radians, converted to minutes.
double _circularDeviationMinutes(List<double> minutes) {
  var sinSum = 0.0;
  var cosSum = 0.0;
  for (final minute in minutes) {
    final angle = 2 * math.pi * minute / _minutesPerDay;
    sinSum += math.sin(angle);
    cosSum += math.cos(angle);
  }

  final resultant =
      math.sqrt(sinSum * sinSum + cosSum * cosSum) / minutes.length;
  if (resultant <= 0) return _minutesPerDay / 2;
  if (resultant >= 1) return 0;

  final radians = math.sqrt(-2 * math.log(resultant));
  return math.min(_minutesPerDay / 2, radians * _minutesPerDay / (2 * math.pi));
}

double _signedOffset(double minute, double mean) {
  final offset = (minute - mean) % _minutesPerDay;
  return offset > _minutesPerDay / 2 ? offset - _minutesPerDay : offset;
}

double _wrapMinutesDouble(double minutes) {
  final wrapped = minutes % _minutesPerDay;
  return wrapped < 0 ? wrapped + _minutesPerDay : wrapped;
}

int _wrapMinutes(int minutes) => minutes % _minutesPerDay;
