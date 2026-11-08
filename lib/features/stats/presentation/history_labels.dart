import 'package:intl/intl.dart';

import '../../../core/time/clock_format.dart';
import '../../../l10n/l10n.dart';

/// Locale-aware labels shared by the history cards and spoken labels.
extension HistoryLabels on AppLocalizations {
  /// The overline under a history row, for example `Today`, `Yesterday` or
  /// `Tue, Oct 20`. Dates from another year include the year.
  ///
  /// [day] and [today] are calendar dates; [today] is usually local midnight.
  String formatHistoryDay(DateTime day, DateTime today) {
    final date = _calendarDate(day);
    final current = _calendarDate(today);

    if (date == current) return this.today;
    if (date == _previousDay(current)) return yesterday;

    final format = date.year == current.year
        ? DateFormat.MMMEd(localeName)
        : DateFormat.yMMMEd(localeName);
    return format.format(date);
  }

  /// The full date used in spoken labels, for example `Tuesday, October 20`.
  String formatHistoryDaySpoken(DateTime day, DateTime today) {
    final date = _calendarDate(day);
    final current = _calendarDate(today);

    if (date == current) return this.today;
    if (date == _previousDay(current)) return yesterday;

    final format = date.year == current.year
        ? DateFormat.MMMMEEEEd(localeName)
        : DateFormat.yMMMMEEEEd(localeName);
    return format.format(date);
  }

  /// A session's start and end, for example `10:32 PM - 6:45 AM`.
  String formatHistoryTimeRange(
    DateTime start,
    DateTime end, {
    required bool use24HourFormat,
  }) {
    final from = formatSessionTime(
      start,
      use24HourFormat: use24HourFormat,
      localeName: localeName,
    );
    final to = formatSessionTime(
      end,
      use24HourFormat: use24HourFormat,
      localeName: localeName,
    );
    return timeRangeSeparator(from, to);
  }

  /// A session's start and end for screen readers, for example
  /// `10:32 PM to 6:45 AM`.
  String formatHistoryTimeRangeSpoken(
    DateTime start,
    DateTime end, {
    required bool use24HourFormat,
  }) {
    final from = formatSessionTime(
      start,
      use24HourFormat: use24HourFormat,
      localeName: localeName,
    );
    final to = formatSessionTime(
      end,
      use24HourFormat: use24HourFormat,
      localeName: localeName,
    );
    return timeRangeSpoken(from, to);
  }

  /// The source pill on a session written by another app.
  ///
  /// Android resolves the writer package label when the app is installed;
  /// [appLabel] is null otherwise and the generic fallback is used.
  String formatExternalSessionLabel(String? appLabel) {
    return appLabel ?? anotherApp;
  }

  /// The spoken prefix for a session written by another app, for example
  /// `Read-only, from Samsung Health`.
  String formatExternalSessionSpokenLabel(String? appLabel) {
    return readOnlyFrom(appLabel ?? anotherAppLower);
  }
}

DateTime _calendarDate(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

DateTime _previousDay(DateTime day) =>
    DateTime(day.year, day.month, day.day - 1);
