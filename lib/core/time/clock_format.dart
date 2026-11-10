import 'package:intl/intl.dart';

/// The live clock face, for example `22:30:05` or `10:30:05`.
///
/// 24-hour mode always uses two digits for the hour. 12-hour mode drops the
/// leading zero; the period is rendered separately with [formatDayPeriod].
String formatClockTime(DateTime time, {required bool use24HourFormat}) {
  final minute = _twoDigits(time.minute);
  final second = _twoDigits(time.second);
  if (use24HourFormat) {
    return '${_twoDigits(time.hour)}:$minute:$second';
  }
  return '${_hour12(time.hour)}:$minute:$second';
}

/// The period next to a 12-hour clock, localized: `AM`/`PM` or `a. m.`/`p. m.`.
String formatDayPeriod(DateTime time, {required String localeName}) {
  final period = DateFormat('a', localeName).format(time);
  return period;
}

/// The time used in the session line, for example `22:30` or `10:30 PM`.
///
/// Seconds are left out here: the exact second is noise in a sentence.
String formatSessionTime(
  DateTime time, {
  required bool use24HourFormat,
  required String localeName,
}) {
  final minute = _twoDigits(time.minute);
  if (use24HourFormat) {
    return '${_twoDigits(time.hour)}:$minute';
  }
  final period = formatDayPeriod(time, localeName: localeName);
  return '${_hour12(time.hour)}:$minute $period';
}

/// A compact hour for chart axes, for example `18:00` or `6 PM`.
///
/// The 12-hour form is built here instead of using the `jm` skeleton because
/// `jm` follows the locale's preferred hour cycle: Spanish prefers 24 hours, so
/// it would ignore the app's 12-hour setting.
String formatHourLabel(
  DateTime time, {
  required bool use24HourFormat,
  required String localeName,
}) {
  if (use24HourFormat) {
    return DateFormat('Hm', localeName).format(time);
  }
  final period = formatDayPeriod(time, localeName: localeName);
  return '${_hour12(time.hour)} $period';
}

/// The date under the clock, for example `Tuesday, October 20` or
/// `martes, 20 de octubre`.
String formatClockDate(DateTime time, {required String localeName}) {
  return DateFormat.MMMMEEEEd(localeName).format(time);
}

/// A single spoken string for the clock, including the period in 12-hour mode.
String formatClockLabel(
  DateTime time, {
  required bool use24HourFormat,
  required String localeName,
}) {
  final clock = formatClockTime(time, use24HourFormat: use24HourFormat);
  if (use24HourFormat) return clock;
  final period = formatDayPeriod(time, localeName: localeName);
  return '$clock $period';
}

int _hour12(int hour) {
  final value = hour % 12;
  return value == 0 ? 12 : value;
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
