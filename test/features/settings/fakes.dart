import 'package:sleepy3/features/health/domain/sleep_data_source.dart';
import 'package:sleepy3/features/settings/domain/app_theme_mode.dart';
import 'package:sleepy3/features/settings/domain/settings_store.dart';

class FakeSettingsStore implements SettingsStore {
  FakeSettingsStore({
    this.mode = AppThemeMode.system,
    this.sleepDataSource = SleepDataSource.local,
    this.failWrites = false,
  });

  AppThemeMode mode;
  SleepDataSource sleepDataSource;
  bool failWrites;
  int loads = 0;
  int sourceLoads = 0;
  final saves = <AppThemeMode>[];
  final sourceSaves = <SleepDataSource>[];

  @override
  Future<AppThemeMode> loadThemeMode() async {
    loads++;
    return mode;
  }

  @override
  Future<void> saveThemeMode(AppThemeMode value) async {
    if (failWrites) throw StateError('write failed');
    mode = value;
    saves.add(value);
  }

  @override
  Future<SleepDataSource> loadSleepDataSource() async {
    sourceLoads++;
    return sleepDataSource;
  }

  @override
  Future<void> saveSleepDataSource(SleepDataSource value) async {
    if (failWrites) throw StateError('write failed');
    sleepDataSource = value;
    sourceSaves.add(value);
  }
}
