import '../../sleep_tracking/domain/sleep_session.dart';
import 'stored_sleep_session.dart';

/// Persistence boundary for Health Connect sync metadata.
///
/// Sessions themselves stay in the sleep tracking tables; this store only
/// answers sync questions and updates the metadata columns.
abstract interface class HealthSyncStore {
  /// Closed local sessions that still need uploading, oldest first.
  Future<List<StoredSleepSession>> loadPendingUploads();

  /// The most recent pending local session, or null when none are pending.
  Future<StoredSleepSession?> loadLatestPendingUpload();

  /// Records a successful upload and stamps the sync time.
  Future<void> markUploaded(
    int rowId,
    String healthRecordId,
    DateTime syncedAt,
  );

  /// Marks a session as not eligible for upload, such as a zero duration.
  Future<void> markSkipped(int rowId);

  /// Finds the row that already holds [healthRecordId], if any.
  Future<StoredSleepSession?> findByHealthRecordId(String healthRecordId);

  /// Finds a session with exactly these start and end times, regardless of
  /// origin. Used to deduplicate downloads that have no UUID.
  Future<StoredSleepSession?> findByExactTimes(
    DateTime startedAt,
    DateTime endedAt,
  );

  /// Inserts a downloaded session and returns its Drift row id.
  ///
  /// Downloaded rows never become pending uploads. The session must be closed;
  /// an empty [healthRecordId] is stored as null.
  Future<int> insertDownloaded(
    SleepSession session,
    String? healthRecordId,
    DateTime syncedAt,
  );

  /// Updates the times of a downloaded row.
  ///
  /// Returns false without writing when [rowId] is not a downloaded row, so a
  /// download can never overwrite a local session.
  Future<bool> updateDownloaded(
    int rowId,
    DateTime startedAt,
    DateTime endedAt,
  );

  /// Number of sessions still waiting to be uploaded.
  Future<int> loadPendingCount();
}
