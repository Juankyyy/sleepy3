/// Formats a sleep duration for the session line, for example `7h 45m` or
/// `35m`. This is presentation-neutral; the UI owns the surrounding copy.
String formatSleepDuration(Duration duration) {
  final safe = duration.isNegative ? Duration.zero : duration;
  final hours = safe.inHours;
  final minutes = safe.inMinutes.remainder(60);
  if (hours == 0) return '${minutes}m';
  return '${hours}h ${minutes}m';
}
