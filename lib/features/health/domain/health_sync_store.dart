import '../../sleep_tracking/domain/sleep_session.dart';
import 'stored_sleep_session.dart';

/// Persistence boundary for Health Connect sync metadata.
///
/// Sessions themselves stay in the sleep tracking tables; this store only
/// answers sync questions and updates the metadata columns.
abstract interface class HealthSyncStore {
  /// Closed local sessions that still need uploading, oldest first.
  Future<List<StoredSleepSession>> loadPendingUploads();

  /// Pending uploads that already have a Health Connect record.
  ///
  /// These are edits of synchronized sessions, not new records. Used by Local
  /// mode so it can retry an update without uploading a new session.
  Future<List<StoredSleepSession>> loadPendingUpdates();

  /// The most recent pending local session, or null when none is pending.
  Future<StoredSleepSession?> loadLatestPendingUpload();

  /// Saves the record version before the platform write is attempted.
  ///
  /// Persisting it first means a retry always uses a higher version even when
  /// the previous attempt failed after Health Connect saw it.
  Future<void> markUploadAttempt(int rowId, int version);

  /// Records a successful upload and stamps the sync time.
  Future<void> markUploaded(
    int rowId,
    String healthRecordId,
    DateTime syncedAt, {
    required String clientRecordId,
    required int version,
  });

  /// Queues an existing record for an update after a local edit.
  ///
  /// Clears the sync time and the skipped flag so [loadPendingUpdates] returns
  /// the row on the next retry.
  Future<void> markPendingUpdate(int rowId);

  /// Marks a session as not eligible for upload, such as a zero duration.
  Future<void> markSkipped(int rowId);

  /// Finds the row that already holds [healthRecordId], if any.
  Future<StoredSleepSession?> findByHealthRecordId(String healthRecordId);

  /// Finds one row by its Drift id, regardless of origin.
  Future<StoredSleepSession?> findById(int rowId);

  /// Finds a session with exactly these start and end times, regardless of
  /// origin. Used to deduplicate downloads that have no UUID.
  Future<StoredSleepSession?> findByExactTimes(
    DateTime startedAt,
    DateTime endedAt,
  );

  /// Local sessions that already have a Health Connect UUID, oldest first.
  ///
  /// Used to enrich the Google Health history with the matching local copy.
  Future<List<StoredSleepSession>> loadLocalSessionsWithHealthRecordId();

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

  /// Deletes a downloaded row after its Health Connect record is gone.
  ///
  /// Returns false without writing when [rowId] is not a downloaded row, so a
  /// local session is never deleted here.
  Future<bool> deleteDownloaded(int rowId);

  /// Number of sessions still waiting to be uploaded.
  Future<int> loadPendingCount();
}
