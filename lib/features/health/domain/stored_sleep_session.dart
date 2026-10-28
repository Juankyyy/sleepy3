import '../../sleep_tracking/domain/sleep_session.dart';

/// Where a stored sleep session came from.
enum SleepSessionOrigin {
  /// Started in Sleepy3 and kept in Drift.
  local('local'),

  /// Downloaded from Health Connect, written by any app.
  healthConnect('healthConnect');

  const SleepSessionOrigin(this.storageValue);

  /// Value stored in the `origin` column.
  final String storageValue;

  /// Parses a stored value, falling back to [local] for unknown data.
  static SleepSessionOrigin fromStorageValue(String? value) {
    for (final origin in values) {
      if (origin.storageValue == value) return origin;
    }
    return local;
  }
}

/// A Drift row together with its Health Connect sync metadata.
class StoredSleepSession {
  const StoredSleepSession({
    required this.id,
    required this.session,
    this.healthRecordId,
    this.healthSyncedAt,
    this.healthSyncSkipped = false,
    this.origin = SleepSessionOrigin.local,
  });

  /// Drift row id, used to update metadata without matching times again.
  final int id;

  final SleepSession session;

  /// Health Connect UUID once the record is uploaded or downloaded.
  final String? healthRecordId;

  /// When the record was last synced with Health Connect, if ever.
  final DateTime? healthSyncedAt;

  /// True when the session cannot be uploaded, such as a zero duration.
  final bool healthSyncSkipped;

  final SleepSessionOrigin origin;

  bool get isUploaded => healthSyncedAt != null;

  /// Whether this session still has to be written to Health Connect.
  ///
  /// Only sessions started in Sleepy3 are uploaded. Downloaded and open
  /// sessions are never pending, and neither are skipped ones.
  bool get isPendingUpload =>
      origin == SleepSessionOrigin.local &&
      !session.isOpen &&
      !isUploaded &&
      !healthSyncSkipped;

  @override
  String toString() =>
      'StoredSleepSession(id: $id, session: $session, '
      'healthRecordId: $healthRecordId, origin: $origin, '
      'healthSyncedAt: $healthSyncedAt, '
      'healthSyncSkipped: $healthSyncSkipped)';
}
