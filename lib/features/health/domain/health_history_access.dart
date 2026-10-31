/// Whether Sleepy3 can read Health Connect records older than the fallback
/// window.
enum HealthHistoryAccess {
  /// The permission has not been checked yet.
  unknown,

  /// Google Health may return the full Health Connect history.
  authorized,

  /// The user declined, or the platform could not answer. Reads stop at
  /// [healthConnectHistoryLimit].
  denied,
}

/// How far back Health Connect returns records without the history permission.
///
/// Android only grants access to records from the last 30 days unless the
/// `READ_HEALTH_DATA_HISTORY` permission is allowed. Sleepy3 applies the same
/// window itself so the visible history is deterministic and the UI can
/// explain the limit.
const Duration healthConnectHistoryLimit = Duration(days: 30);
