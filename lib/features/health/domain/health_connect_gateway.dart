import 'health_sleep_session.dart';

/// The ids Health Connect needs to replace an existing Sleepy3 record.
class HealthRecordWriteToken {
  const HealthRecordWriteToken({
    required this.clientRecordId,
    required this.clientRecordVersion,
  });

  /// Stable client id assigned by Sleepy3 when the record was written.
  final String clientRecordId;

  /// Version currently stored by Health Connect.
  final int clientRecordVersion;
}

/// The identity of a Sleepy3 record after an update.
class HealthRecordUpdate {
  const HealthRecordUpdate({
    required this.healthRecordId,
    required this.clientRecordId,
    required this.clientRecordVersion,
  });

  /// Health Connect UUID of the updated record.
  ///
  /// An upsert can assign a new UUID, so callers must replace the old one.
  final String healthRecordId;

  /// Stable client id used for the write.
  final String clientRecordId;

  /// Version written to Health Connect.
  final int clientRecordVersion;
}

/// What happened when Sleepy3 tried to delete a record.
enum SleepRecordDeleteResult {
  /// The platform confirmed the deletion.
  deleted,

  /// The record no longer exists; there is nothing left to delete.
  notFound,

  /// Health Connect rejected the call, usually because the record belongs to
  /// another package or the write permission is missing.
  permission,

  /// The platform call failed for another reason.
  failed,
}

/// Whether Health Connect can be used on this device.
enum HealthConnectAvailability {
  /// Health Connect is installed and the SDK is current.
  available,

  /// Health Connect is installed but needs to be updated from the store.
  updateRequired,

  /// Health Connect is not installed or is not supported on this device.
  unavailable,
}

/// Platform boundary for Google Health Connect.
///
/// Everything that talks to the `health` plugin goes through this interface so
/// the app logic can be tested with a fake.
abstract interface class HealthConnectGateway {
  /// Checks whether Health Connect is installed and up to date.
  Future<HealthConnectAvailability> checkAvailability();

  /// Whether the requested sleep permissions are already granted.
  ///
  /// With neither [read] nor [write] set this returns true without touching the
  /// platform. A missing Health Connect always reports false.
  Future<bool> hasPermissions({bool read = true, bool write = false});

  /// Shows the Health Connect permission dialog for the requested access.
  ///
  /// Returns whether every requested permission is granted after the dialog,
  /// not merely whether the dialog was shown.
  Future<bool> requestPermissions({bool read = true, bool write = false});

  /// Asks for access to Health Connect history older than 30 days.
  ///
  /// Returns whether the permission is granted after the dialog.
  Future<bool> requestHistoryPermission();

  /// Whether the app can read health history older than 30 days.
  Future<bool> isHistoryAuthorized();

  /// Reads every `SLEEP_SESSION` in `[from, to]`, oldest first.
  ///
  /// Records from every app are returned, including Sleepy3's own. Invalid
  /// records are left out only by the platform, not by this gateway.
  Future<List<HealthSleepSession>> readSleepSessions({
    required DateTime from,
    required DateTime to,
  });

  /// Writes one `SLEEP_SESSION` and returns its Health Connect UUID.
  ///
  /// [clientRecordId] is the stable id; writing again with the same id and a
  /// higher [clientRecordVersion] updates that record instead of creating a
  /// duplicate. Returns null when Health Connect rejects the write. Throws when
  /// the platform call itself fails; callers keep the session pending and retry.
  Future<String?> writeSleepSession({
    required DateTime startedAt,
    required DateTime endedAt,
    required String clientRecordId,
    required int clientRecordVersion,
  });

  /// Reads the stable ids Health Connect stored for one Sleepy3 record.
  ///
  /// Returns null when the record does not exist, belongs to another package,
  /// has no client id, or the platform cannot answer. The ids are the ones the
  /// running build must reuse to replace the record without creating a
  /// duplicate.
  Future<HealthRecordWriteToken?> readSleepSessionWriteToken(
    String healthRecordId,
  );

  /// Updates a sleep record written by Sleepy3, even without a local copy.
  ///
  /// Reads the record's stable client id and version from Health Connect and
  /// writes the new times with the next version, so the same record is
  /// replaced. Returns the new identity, or null when the record has no stable
  /// id, belongs to another app, or the platform rejects the update. Throws
  /// when the platform call itself fails.
  Future<HealthRecordUpdate?> updateSleepSession({
    required String healthRecordId,
    required DateTime startedAt,
    required DateTime endedAt,
  });

  /// Deletes one sleep record written by Sleepy3.
  ///
  /// Pass one id at a time: [healthRecordId] or [clientRecordId]. Health
  /// Connect only lets the package that wrote a record delete it. The result
  /// distinguishes a missing record from a permission rejection so callers can
  /// repair stale ids or explain the failure.
  Future<SleepRecordDeleteResult> deleteSleepSession({
    String? clientRecordId,
    String? healthRecordId,
  });

  /// Opens the store page so the user can install or update Health Connect.
  Future<void> installHealthConnect();
}
