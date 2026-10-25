import 'package:intl/intl.dart';

import '../../../core/time/clock_format.dart';

/// The overline under a history row, for example `Today`, `Yesterday` or
/// `Tue, Oct 20`. Dates from another year include the year.
///
/// [day] and [today] are calendar dates; [today] is usually local midnight.
/// The app is English-only, so the format is fixed to `en_US` instead of
/// following the device locale.
String formatHistoryDay(DateTime day, DateTime today) {
  final date = _calendarDate(day);
  final current = _calendarDate(today);

  if (date == current) return 'Today';
  if (date == _previousDay(current)) return 'Yesterday';

  final pattern = date.year == current.year ? 'EEE, MMM d' : 'EEE, MMM d, y';
  return DateFormat(pattern, 'en_US').format(date);
}

/// The full date used in spoken labels, for example `Tuesday, October 20`.
String formatHistoryDaySpoken(DateTime day, DateTime today) {
  final date = _calendarDate(day);
  final current = _calendarDate(today);

  if (date == current) return 'Today';
  if (date == _previousDay(current)) return 'Yesterday';

  final pattern = date.year == current.year
      ? 'EEEE, MMMM d'
      : 'EEEE, MMMM d, y';
  return DateFormat(pattern, 'en_US').format(date);
}

/// A session's start and end, for example `10:32 PM – 6:45 AM`.
String formatHistoryTimeRange(
  DateTime start,
  DateTime end, {
  required bool use24HourFormat,
}) {
  final from = formatSessionTime(start, use24HourFormat: use24HourFormat);
  final to = formatSessionTime(end, use24HourFormat: use24HourFormat);
  return '$from – $to';
}

/// A session's start and end for screen readers, for example
/// `10:32 PM to 6:45 AM`.
String formatHistoryTimeRangeSpoken(
  DateTime start,
  DateTime end, {
  required bool use24HourFormat,
}) {
  final from = formatSessionTime(start, use24HourFormat: use24HourFormat);
  final to = formatSessionTime(end, use24HourFormat: use24HourFormat);
  return '$from to $to';
}

DateTime _calendarDate(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

DateTime _previousDay(DateTime day) =>
    DateTime(day.year, day.month, day.day - 1);
