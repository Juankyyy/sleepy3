import '../../sleep_tracking/data/sleepy3_database.dart';
import '../domain/app_theme_mode.dart';
import '../domain/settings_store.dart';

/// Stores settings in the app's single Drift database.
class DriftSettingsStore implements SettingsStore {
  DriftSettingsStore(this._db);

  final Sleepy3Database _db;

  static const _themeModeKey = 'theme_mode';

  @override
  Future<AppThemeMode> loadThemeMode() async {
    final query = _db.select(_db.preferences)
      ..where((row) => row.settingKey.equals(_themeModeKey));
    final row = await query.getSingleOrNull();
    return AppThemeMode.fromStorageValue(row?.settingValue);
  }

  @override
  Future<void> saveThemeMode(AppThemeMode mode) async {
    await _db
        .into(_db.preferences)
        .insertOnConflictUpdate(
          PreferencesCompanion.insert(
            settingKey: _themeModeKey,
            settingValue: mode.name,
          ),
        );
  }
}
