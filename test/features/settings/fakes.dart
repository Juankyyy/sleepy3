import 'package:sleepy3/features/health/domain/sleep_data_source.dart';
import 'package:sleepy3/features/reminders/domain/sleep_reminder.dart';
import 'package:sleepy3/features/settings/domain/app_language.dart';
import 'package:sleepy3/features/settings/domain/app_theme_mode.dart';
import 'package:sleepy3/features/settings/domain/app_time_format.dart';
import 'package:sleepy3/features/settings/domain/settings_store.dart';

class FakeSettingsStore implements SettingsStore {
  FakeSettingsStore({
    this.mode = AppThemeMode.system,
    this.timeFormat,
    this.language,
    this.sleepDataSource = SleepDataSource.local,
    this.sleepReminder = SleepReminder.defaults,
    this.failWrites = false,
  });

  AppThemeMode mode;
  AppTimeFormat? timeFormat;
  AppLanguage? language;
  SleepDataSource sleepDataSource;
  SleepReminder sleepReminder;
  bool failWrites;
  int loads = 0;
  int timeFormatLoads = 0;
  int languageLoads = 0;
  int sourceLoads = 0;
  int reminderLoads = 0;
  final saves = <AppThemeMode>[];
  final timeFormatSaves = <AppTimeFormat>[];
  final languageSaves = <AppLanguage>[];
  final sourceSaves = <SleepDataSource>[];
  final reminderSaves = <SleepReminder>[];

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
  Future<AppTimeFormat?> loadTimeFormat() async {
    timeFormatLoads++;
    return timeFormat;
  }

  @override
  Future<void> saveTimeFormat(AppTimeFormat value) async {
    if (failWrites) throw StateError('write failed');
    timeFormat = value;
    timeFormatSaves.add(value);
  }

  @override
  Future<AppLanguage?> loadLanguage() async {
    languageLoads++;
    return language;
  }

  @override
  Future<void> saveLanguage(AppLanguage value) async {
    if (failWrites) throw StateError('write failed');
    language = value;
    languageSaves.add(value);
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

  @override
  Future<SleepReminder> loadSleepReminder() async {
    reminderLoads++;
    return sleepReminder;
  }

  @override
  Future<void> saveSleepReminder(SleepReminder value) async {
    if (failWrites) throw StateError('write failed');
    sleepReminder = value;
    reminderSaves.add(value);
  }
}
