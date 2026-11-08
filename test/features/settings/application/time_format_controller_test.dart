import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/health/domain/sleep_data_source.dart';
import 'package:sleepy3/features/settings/application/time_format_controller.dart';
import 'package:sleepy3/features/settings/domain/app_theme_mode.dart';
import 'package:sleepy3/features/settings/domain/app_time_format.dart';
import 'package:sleepy3/features/settings/domain/settings_store.dart';

import '../fakes.dart';

void main() {
  group('TimeFormatController', () {
    test('starts with the startup preference', () {
      final container = ProviderContainer.test(
        overrides: [
          settingsStoreProvider.overrideWithValue(FakeSettingsStore()),
          initialTimeFormatProvider.overrideWithValue(
            AppTimeFormat.twentyFourHour,
          ),
        ],
      );

      expect(
        container.read(timeFormatControllerProvider),
        AppTimeFormat.twentyFourHour,
      );
    });

    test('updates immediately and persists the new format', () async {
      final store = FakeSettingsStore();
      final container = ProviderContainer.test(
        overrides: [settingsStoreProvider.overrideWithValue(store)],
      );
      final controller = container.read(timeFormatControllerProvider.notifier);

      await controller.setFormat(AppTimeFormat.twentyFourHour);

      expect(
        container.read(timeFormatControllerProvider),
        AppTimeFormat.twentyFourHour,
      );
      expect(store.timeFormatSaves, [AppTimeFormat.twentyFourHour]);
    });

    test('selecting the current format does not write again', () async {
      final store = FakeSettingsStore(timeFormat: AppTimeFormat.twentyFourHour);
      final container = ProviderContainer.test(
        overrides: [
          settingsStoreProvider.overrideWithValue(store),
          initialTimeFormatProvider.overrideWithValue(
            AppTimeFormat.twentyFourHour,
          ),
        ],
      );
      final controller = container.read(timeFormatControllerProvider.notifier);

      await controller.setFormat(AppTimeFormat.twentyFourHour);

      expect(store.timeFormatSaves, isEmpty);
    });

    test('keeps the visible format when a write fails', () async {
      final store = FakeSettingsStore(failWrites: true);
      final container = ProviderContainer.test(
        overrides: [settingsStoreProvider.overrideWithValue(store)],
      );
      final controller = container.read(timeFormatControllerProvider.notifier);

      await controller.setFormat(AppTimeFormat.twentyFourHour);

      expect(
        container.read(timeFormatControllerProvider),
        AppTimeFormat.twentyFourHour,
      );
      expect(store.timeFormatSaves, isEmpty);
    });

    test('serializes rapid changes and the last one wins', () async {
      final store = _ControlledSettingsStore();
      final container = ProviderContainer.test(
        overrides: [settingsStoreProvider.overrideWithValue(store)],
      );
      final controller = container.read(timeFormatControllerProvider.notifier);

      final first = controller.setFormat(AppTimeFormat.twentyFourHour);
      final second = controller.setFormat(AppTimeFormat.twelveHour);

      await Future<void>.delayed(Duration.zero);
      expect(store.writes, [AppTimeFormat.twentyFourHour]);

      store.pending.single.complete();
      await Future<void>.delayed(Duration.zero);
      expect(store.writes, [
        AppTimeFormat.twentyFourHour,
        AppTimeFormat.twelveHour,
      ]);

      store.pending.last.complete();
      await Future.wait([first, second]);

      expect(
        container.read(timeFormatControllerProvider),
        AppTimeFormat.twelveHour,
      );
      expect(store.writes, [
        AppTimeFormat.twentyFourHour,
        AppTimeFormat.twelveHour,
      ]);
    });
  });
}

class _ControlledSettingsStore implements SettingsStore {
  final writes = <AppTimeFormat>[];
  final pending = <Completer<void>>[];

  @override
  Future<AppThemeMode> loadThemeMode() async => AppThemeMode.system;

  @override
  Future<void> saveThemeMode(AppThemeMode mode) async {}

  @override
  Future<AppTimeFormat?> loadTimeFormat() async => null;

  @override
  Future<void> saveTimeFormat(AppTimeFormat format) {
    writes.add(format);
    final completer = Completer<void>();
    pending.add(completer);
    return completer.future;
  }

  @override
  Future<SleepDataSource> loadSleepDataSource() async => SleepDataSource.local;

  @override
  Future<void> saveSleepDataSource(SleepDataSource source) async {}
}
