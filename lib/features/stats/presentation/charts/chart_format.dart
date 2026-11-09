import 'package:intl/intl.dart';

import '../../../../core/time/clock_format.dart';
import '../../../../l10n/l10n.dart';
import '../../../sleep_tracking/domain/sleep_history.dart';

/// The left edge of the sleep-window axis: 18:00.
const sleepWindowAxisStart = 18 * 60;

/// The right edge of the sleep-window axis: 12:00 the next day.
const sleepWindowAxisEnd = 36 * 60;

/// Maps a wall-clock time to minutes from 18:00 on the sleep-window axis.
///
/// A bedtime or wake time after midnight belongs to the right side of the
/// axis, so 00:30 is 24.5 hours rather than 0.5. A time between noon and 18:00
/// is outside the window and clamps to the nearest edge.
double? sleepWindowAxisMinutes(Duration? time) {
  if (time == null) return null;
  final minutes = time.inMinutes.remainder(24 * 60);
  final onAxis = minutes < sleepWindowAxisStart ? minutes + 24 * 60 : minutes;
  return onAxis.clamp(sleepWindowAxisStart, sleepWindowAxisEnd).toDouble();
}

/// The localized label for a Stats range chip.
String chartRangeLabel(AppLocalizations l10n, SleepHistoryRange range) {
  return switch (range) {
    SleepHistoryRange.week => l10n.rangeWeek,
    SleepHistoryRange.month => l10n.rangeMonth,
    SleepHistoryRange.threeMonths => l10n.rangeThreeMonths,
    SleepHistoryRange.year => l10n.rangeYear,
    SleepHistoryRange.all => l10n.rangeAll,
  };
}

/// A wall-clock time for chart labels, such as `10:32 PM` or `22:32`.
///
/// [time] is a duration since local midnight, as returned by
/// [SleepInsights.averageBedtime]. Values past 24 hours wrap to the next day,
/// which only affects the hidden date, not the displayed hour.
String chartClockLabel({
  required AppLocalizations l10n,
  required Duration time,
  required bool use24HourFormat,
}) {
  final clock = DateTime(2000).add(time);
  return formatSessionTime(
    clock,
    use24HourFormat: use24HourFormat,
    localeName: l10n.localeName,
  );
}

/// An hour label for a chart axis, such as `6 PM` or `18:00`.
String chartHourLabel({
  required AppLocalizations l10n,
  required int hour,
  required bool use24HourFormat,
}) {
  final date = DateTime(2000, 1, 1, hour);
  final pattern = use24HourFormat ? 'Hm' : 'jm';
  return DateFormat(pattern, l10n.localeName).format(date);
}

/// The short weekday name used under the weekday chart: `Mon` or `lun`.
String chartWeekdayShort(AppLocalizations l10n, int weekday) {
  final date = DateTime(2024, 1, 1 + weekday - DateTime.monday);
  return DateFormat.E(l10n.localeName).format(date);
}

/// The full weekday name used in tooltips and spoken summaries.
String chartWeekdayLong(AppLocalizations l10n, int weekday) {
  final date = DateTime(2024, 1, 1 + weekday - DateTime.monday);
  return DateFormat.EEEE(l10n.localeName).format(date);
}
