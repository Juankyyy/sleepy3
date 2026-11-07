/// The shortest sleep a session can record.
///
/// Health Connect rejects sleep records shorter than this, so Sleepy3 never
/// registers them, in any data source mode: they are treated as an
/// accidental Sleep / Wake tap or as legacy rows to clean up.
const Duration minimumRecordableSleep = Duration(minutes: 10);

/// The longest sleep a session can record.
///
/// Health Connect rejects sleep records of 24 hours or more, so Sleepy3
/// never registers them, in any data source mode. A session that has been
/// open for longer can be fixed by moving its start before it is closed.
const Duration maximumRecordableSleep = Duration(hours: 24);

/// One sleep session.
///
/// A session starts when the user taps "Sleep" and ends when they tap
/// "Wake". An open session has no [endedAt] yet.
///
/// Sessions read from Health Connect carry the record identity and the app
/// that wrote it. Rows stored in Drift carry [localId] instead, so the session
/// editor can find and update the row later without matching times again.
class SleepSession {
  const SleepSession({
    required this.startedAt,
    this.endedAt,
    this.localId,
    this.isDownloaded = false,
    this.healthRecordId,
    this.healthClientRecordId,
    this.sourceId,
  });

  final DateTime startedAt;
  final DateTime? endedAt;

  /// Drift row id when a local copy of this session exists.
  ///
  /// Null for Health Connect records that were never copied locally.
  final int? localId;

  /// Whether the local row was downloaded from Health Connect.
  ///
  /// Downloaded rows are read-only copies in Local mode: a later import may
  /// replace them.
  final bool isDownloaded;

  /// Health Connect UUID once the record is uploaded or downloaded.
  final String? healthRecordId;

  /// Stable id used to update the same Health Connect record.
  ///
  /// A local session with this id can push an edit to Health Connect without
  /// creating a duplicate.
  final String? healthClientRecordId;

  /// Package name of the app that wrote the Health Connect record.
  ///
  /// Null for sessions that only exist in the local database.
  final String? sourceId;

  bool get isOpen => endedAt == null;

  /// Whether Local mode can edit this session in place.
  ///
  /// Downloaded rows are copies of another app's record and stay read-only.
  bool get isEditableLocal => localId != null && !isDownloaded;

  /// Time slept. Returns [Duration.zero] while the session is still open.
  Duration get duration {
    final end = endedAt;
    if (end == null) return Duration.zero;
    return end.difference(startedAt);
  }

  /// Whether both values describe the same stored session.
  ///
  /// The Drift row id wins when both sessions have one; otherwise the Health
  /// Connect UUID identifies the session. Two sessions with neither id are only
  /// equal when they are the same object.
  bool hasSameIdentityAs(SleepSession other) {
    final local = localId;
    if (local != null && other.localId != null) return local == other.localId;

    final record = healthRecordId;
    if (record != null && other.healthRecordId != null) {
      return record == other.healthRecordId;
    }
    return identical(this, other);
  }

  /// A copy of this session with new times and the same identity metadata.
  SleepSession withTimes(DateTime startedAt, DateTime endedAt) {
    return SleepSession(
      startedAt: startedAt,
      endedAt: endedAt,
      localId: localId,
      isDownloaded: isDownloaded,
      healthRecordId: healthRecordId,
      healthClientRecordId: healthClientRecordId,
      sourceId: sourceId,
    );
  }

  /// A copy of this session with a different Health Connect identity.
  ///
  /// A Health Connect upsert can assign a new UUID, so the editor must replace
  /// the id it opened with. The local row id and source are preserved.
  SleepSession withHealthIdentity({
    String? healthRecordId,
    String? healthClientRecordId,
  }) {
    return SleepSession(
      startedAt: startedAt,
      endedAt: endedAt,
      localId: localId,
      isDownloaded: isDownloaded,
      healthRecordId: healthRecordId,
      healthClientRecordId: healthClientRecordId,
      sourceId: sourceId,
    );
  }

  /// A copy of this session with a new start and the same identity metadata.
  ///
  /// Used to fix a session that has been open for longer than
  /// [maximumRecordableSleep] before closing it. The session stays open when
  /// it had no end.
  SleepSession retimeStart(DateTime startedAt) {
    return SleepSession(
      startedAt: startedAt,
      endedAt: endedAt,
      localId: localId,
      isDownloaded: isDownloaded,
      healthRecordId: healthRecordId,
      healthClientRecordId: healthClientRecordId,
      sourceId: sourceId,
    );
  }

  SleepSession finish(DateTime at) {
    final end = at.isBefore(startedAt) ? startedAt : at;
    return SleepSession(
      startedAt: startedAt,
      endedAt: end,
      localId: localId,
      isDownloaded: isDownloaded,
      healthRecordId: healthRecordId,
      healthClientRecordId: healthClientRecordId,
      sourceId: sourceId,
    );
  }

  @override
  String toString() =>
      'SleepSession(startedAt: $startedAt, endedAt: $endedAt, '
      'localId: $localId, sourceId: $sourceId)';
}
