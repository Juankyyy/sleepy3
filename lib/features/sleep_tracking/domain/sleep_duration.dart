/// Formats a sleep duration for the session line, for example `7h 45m` or
/// `35m`. This is presentation-neutral; the UI owns the surrounding copy.
String formatSleepDuration(Duration duration) {
  final safe = duration.isNegative ? Duration.zero : duration;
  final hours = safe.inHours;
  final minutes = safe.inMinutes.remainder(60);
  if (hours == 0) return '${minutes}m';
  return '${hours}h ${minutes}m';
}

/// Spells out a duration for screen readers, for example
/// `7 hours 45 minutes`. Zero and negative durations are spoken as
/// `0 minutes`.
String formatSpokenSleepDuration(Duration duration) {
  final safe = duration.isNegative ? Duration.zero : duration;
  final hours = safe.inHours;
  final minutes = safe.inMinutes.remainder(60);
  final hourPart = hours == 0 ? '' : '$hours ${hours == 1 ? 'hour' : 'hours'}';
  final minutePart = '$minutes ${minutes == 1 ? 'minute' : 'minutes'}';
  return hours == 0 ? minutePart : '$hourPart $minutePart';
}
