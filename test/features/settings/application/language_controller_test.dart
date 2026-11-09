import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/health/domain/sleep_data_source.dart';
import 'package:sleepy3/features/reminders/domain/sleep_reminder.dart';
import 'package:sleepy3/features/settings/application/language_controller.dart';
import 'package:sleepy3/features/settings/domain/app_language.dart';
import 'package:sleepy3/features/settings/domain/app_theme_mode.dart';
import 'package:sleepy3/features/settings/domain/app_time_format.dart';
import 'package:sleepy3/features/settings/domain/settings_store.dart';

import '../fakes.dart';

void main() {
  group('LanguageController', () {
    test('starts with the startup preference', () {
      final container = ProviderContainer.test(
        overrides: [
          settingsStoreProvider.overrideWithValue(FakeSettingsStore()),
          initialLanguageProvider.overrideWithValue(AppLanguage.spanish),
        ],
      );

      expect(container.read(languageControllerProvider), AppLanguage.spanish);
    });

    test('updates immediately and persists the new language', () async {
      final store = FakeSettingsStore();
      final container = ProviderContainer.test(
        overrides: [settingsStoreProvider.overrideWithValue(store)],
      );
      final controller = container.read(languageControllerProvider.notifier);

      await controller.setLanguage(AppLanguage.spanish);

      expect(container.read(languageControllerProvider), AppLanguage.spanish);
      expect(store.languageSaves, [AppLanguage.spanish]);
    });

    test('selecting the current language does not write again', () async {
      final store = FakeSettingsStore(language: AppLanguage.spanish);
      final container = ProviderContainer.test(
        overrides: [
          settingsStoreProvider.overrideWithValue(store),
          initialLanguageProvider.overrideWithValue(AppLanguage.spanish),
        ],
      );
      final controller = container.read(languageControllerProvider.notifier);

      await controller.setLanguage(AppLanguage.spanish);

      expect(store.languageSaves, isEmpty);
    });

    test('keeps the visible language when a write fails', () async {
      final store = FakeSettingsStore(failWrites: true);
      final container = ProviderContainer.test(
        overrides: [settingsStoreProvider.overrideWithValue(store)],
      );
      final controller = container.read(languageControllerProvider.notifier);

      await controller.setLanguage(AppLanguage.spanish);

      expect(container.read(languageControllerProvider), AppLanguage.spanish);
      expect(store.languageSaves, isEmpty);
    });

    test('serializes rapid changes and the last one wins', () async {
      final store = _ControlledSettingsStore();
      final container = ProviderContainer.test(
        overrides: [settingsStoreProvider.overrideWithValue(store)],
      );
      final controller = container.read(languageControllerProvider.notifier);

      final first = controller.setLanguage(AppLanguage.spanish);
      final second = controller.setLanguage(AppLanguage.english);

      await Future<void>.delayed(Duration.zero);
      expect(store.writes, [AppLanguage.spanish]);

      store.pending.single.complete();
      await Future<void>.delayed(Duration.zero);
      expect(store.writes, [AppLanguage.spanish, AppLanguage.english]);

      store.pending.last.complete();
      await Future.wait([first, second]);

      expect(container.read(languageControllerProvider), AppLanguage.english);
      expect(store.writes, [AppLanguage.spanish, AppLanguage.english]);
    });
  });
}

class _ControlledSettingsStore implements SettingsStore {
  final writes = <AppLanguage>[];
  final pending = <Completer<void>>[];

  @override
  Future<AppThemeMode> loadThemeMode() async => AppThemeMode.system;

  @override
  Future<void> saveThemeMode(AppThemeMode mode) async {}

  @override
  Future<AppTimeFormat?> loadTimeFormat() async => null;

  @override
  Future<void> saveTimeFormat(AppTimeFormat format) async {}

  @override
  Future<AppLanguage?> loadLanguage() async => null;

  @override
  Future<void> saveLanguage(AppLanguage language) {
    writes.add(language);
    final completer = Completer<void>();
    pending.add(completer);
    return completer.future;
  }

  @override
  Future<SleepDataSource> loadSleepDataSource() async => SleepDataSource.local;

  @override
  Future<void> saveSleepDataSource(SleepDataSource source) async {}

  @override
  Future<SleepReminder> loadSleepReminder() async => SleepReminder.defaults;

  @override
  Future<void> saveSleepReminder(SleepReminder reminder) async {}

  @override
  Future<bool> loadSleepNotificationPermissionAsked() async => false;

  @override
  Future<void> saveSleepNotificationPermissionAsked(bool asked) async {}
}
