/// One `SLEEP_SESSION` record read from Health Connect.
///
/// Unlike a local sleep session, this is always closed and carries the Health
/// Connect record UUID plus the app that wrote it.
class HealthSleepSession {
  const HealthSleepSession({
    required this.uuid,
    required this.startedAt,
    required this.endedAt,
    this.sourceId = '',
    this.sourceName = '',
  });

  /// The Health Connect record UUID. Empty when the platform did not provide one.
  final String uuid;

  final DateTime startedAt;
  final DateTime endedAt;

  /// Package name of the app that wrote the record.
  final String sourceId;

  /// Human-readable name of the app that wrote the record.
  final String sourceName;

  Duration get duration => endedAt.difference(startedAt);

  @override
  String toString() =>
      'HealthSleepSession(uuid: $uuid, startedAt: $startedAt, '
      'endedAt: $endedAt, sourceName: $sourceName)';
}
