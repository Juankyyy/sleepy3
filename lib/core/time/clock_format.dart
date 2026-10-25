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

/// The period next to a 12-hour clock: `AM` or `PM`.
String formatDayPeriod(DateTime time) => time.hour < 12 ? 'AM' : 'PM';

/// The time used in the session line, for example `22:30` or `10:30 PM`.
///
/// Seconds are left out here: the exact second is noise in a sentence.
String formatSessionTime(DateTime time, {required bool use24HourFormat}) {
  final minute = _twoDigits(time.minute);
  if (use24HourFormat) {
    return '${_twoDigits(time.hour)}:$minute';
  }
  return '${_hour12(time.hour)}:$minute ${formatDayPeriod(time)}';
}

/// The date under the clock, for example `Tuesday, October 20`.
///
/// The app is English-only, so the format is fixed to `en_US` instead of
/// following the device locale.
String formatClockDate(DateTime time) => _dateFormat.format(time);

/// A single spoken string for the clock, including the period in 12-hour mode.
String formatClockLabel(DateTime time, {required bool use24HourFormat}) {
  final clock = formatClockTime(time, use24HourFormat: use24HourFormat);
  return use24HourFormat ? clock : '$clock ${formatDayPeriod(time)}';
}

final _dateFormat = DateFormat('EEEE, MMMM d', 'en_US');

int _hour12(int hour) {
  final value = hour % 12;
  return value == 0 ? 12 : value;
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
