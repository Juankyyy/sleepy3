import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/health/domain/sleep_data_source.dart';
import 'package:sleepy3/features/settings/application/theme_mode_controller.dart';
import 'package:sleepy3/features/settings/domain/app_night_mode.dart';
import 'package:sleepy3/features/settings/domain/app_theme_mode.dart';
import 'package:sleepy3/features/settings/domain/app_time_format.dart';
import 'package:sleepy3/features/settings/domain/settings_store.dart';

import '../fakes.dart';

void main() {
  group('ThemeModeController', () {
    test('starts with the startup preference', () {
      final container = ProviderContainer.test(
        overrides: [
          settingsStoreProvider.overrideWithValue(FakeSettingsStore()),
          initialThemeModeProvider.overrideWithValue(AppThemeMode.dark),
        ],
      );

      expect(container.read(themeModeControllerProvider), AppThemeMode.dark);
    });

    test('updates immediately and persists the new mode', () async {
      final store = FakeSettingsStore();
      final nightMode = _FakeAppNightMode();
      final container = ProviderContainer.test(
        overrides: [
          settingsStoreProvider.overrideWithValue(store),
          appNightModeProvider.overrideWithValue(nightMode),
        ],
      );
      final controller = container.read(themeModeControllerProvider.notifier);

      await controller.setMode(AppThemeMode.light);

      expect(container.read(themeModeControllerProvider), AppThemeMode.light);
      expect(store.saves, [AppThemeMode.light]);
      expect(nightMode.modes, [AppThemeMode.light]);
    });

    test('selecting the current mode does not write again', () async {
      final store = FakeSettingsStore(mode: AppThemeMode.dark);
      final nightMode = _FakeAppNightMode();
      final container = ProviderContainer.test(
        overrides: [
          settingsStoreProvider.overrideWithValue(store),
          initialThemeModeProvider.overrideWithValue(AppThemeMode.dark),
          appNightModeProvider.overrideWithValue(nightMode),
        ],
      );
      final controller = container.read(themeModeControllerProvider.notifier);

      await controller.setMode(AppThemeMode.dark);

      expect(store.saves, isEmpty);
      expect(nightMode.modes, isEmpty);
    });

    test('keeps the visible mode when a write fails', () async {
      final store = FakeSettingsStore(failWrites: true);
      final nightMode = _FakeAppNightMode();
      final container = ProviderContainer.test(
        overrides: [
          settingsStoreProvider.overrideWithValue(store),
          appNightModeProvider.overrideWithValue(nightMode),
        ],
      );
      final controller = container.read(themeModeControllerProvider.notifier);

      await controller.setMode(AppThemeMode.dark);

      expect(container.read(themeModeControllerProvider), AppThemeMode.dark);
      expect(store.saves, isEmpty);
      expect(nightMode.modes, [AppThemeMode.dark]);
    });

    test('serializes rapid changes and the last one wins', () async {
      final store = _ControlledSettingsStore();
      final nightMode = _FakeAppNightMode();
      final container = ProviderContainer.test(
        overrides: [
          settingsStoreProvider.overrideWithValue(store),
          appNightModeProvider.overrideWithValue(nightMode),
        ],
      );
      final controller = container.read(themeModeControllerProvider.notifier);

      final first = controller.setMode(AppThemeMode.light);
      final second = controller.setMode(AppThemeMode.dark);

      await Future<void>.delayed(Duration.zero);
      expect(store.writes, [AppThemeMode.light]);

      store.pending.single.complete();
      await Future<void>.delayed(Duration.zero);
      expect(store.writes, [AppThemeMode.light, AppThemeMode.dark]);

      store.pending.last.complete();
      await Future.wait([first, second]);

      expect(container.read(themeModeControllerProvider), AppThemeMode.dark);
      expect(store.writes, [AppThemeMode.light, AppThemeMode.dark]);
      expect(nightMode.modes, [AppThemeMode.light, AppThemeMode.dark]);
    });
  });
}

class _FakeAppNightMode implements AppNightMode {
  final modes = <AppThemeMode>[];

  @override
  Future<void> setMode(AppThemeMode mode) async {
    modes.add(mode);
  }
}

class _ControlledSettingsStore implements SettingsStore {
  final writes = <AppThemeMode>[];
  final pending = <Completer<void>>[];

  @override
  Future<AppThemeMode> loadThemeMode() async => AppThemeMode.system;

  @override
  Future<void> saveThemeMode(AppThemeMode mode) {
    writes.add(mode);
    final completer = Completer<void>();
    pending.add(completer);
    return completer.future;
  }

  @override
  Future<AppTimeFormat?> loadTimeFormat() async => null;

  @override
  Future<void> saveTimeFormat(AppTimeFormat format) async {}

  @override
  Future<SleepDataSource> loadSleepDataSource() async => SleepDataSource.local;

  @override
  Future<void> saveSleepDataSource(SleepDataSource source) async {}
}
