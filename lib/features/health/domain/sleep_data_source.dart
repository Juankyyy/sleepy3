/// Where Home and Stats read the sleep history from.
///
/// The two sources are never mixed: `local` shows only sessions stored in
/// Drift, and `healthConnect` shows only sessions read from Health Connect.
enum SleepDataSource {
  /// Drift is the source of truth. Health Connect is not read automatically.
  local('local'),

  /// Every `SLEEP_SESSION` in Health Connect, from any app.
  healthConnect('healthConnect');

  const SleepDataSource(this.storageValue);

  /// Value stored in the `preferences` table.
  final String storageValue;

  /// Parses a stored value, falling back to [local] for unknown data.
  static SleepDataSource fromStorageValue(String? value) {
    for (final source in values) {
      if (source.storageValue == value) return source;
    }
    return local;
  }
}
