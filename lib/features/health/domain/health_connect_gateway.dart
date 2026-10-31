import 'health_sleep_session.dart';

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

  /// Deletes a sleep record written by Sleepy3.
  ///
  /// Uses [clientRecordId] when known and falls back to [healthRecordId].
  /// Health Connect itself rejects records written by another app, so callers
  /// must only pass ids from Sleepy3 records. Returns whether the platform
  /// confirmed the deletion; throws when the platform call fails.
  Future<bool> deleteSleepSession({
    String? clientRecordId,
    String? healthRecordId,
  });

  /// Opens the store page so the user can install or update Health Connect.
  Future<void> installHealthConnect();
}
