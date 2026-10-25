import 'package:sleepy3/features/settings/domain/app_theme_mode.dart';
import 'package:sleepy3/features/settings/domain/settings_store.dart';

class FakeSettingsStore implements SettingsStore {
  FakeSettingsStore({this.mode = AppThemeMode.system, this.failWrites = false});

  AppThemeMode mode;
  bool failWrites;
  int loads = 0;
  final saves = <AppThemeMode>[];

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
}
