import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/settings/data/drift_settings_store.dart';
import 'package:sleepy3/features/settings/domain/app_theme_mode.dart';
import 'package:sleepy3/features/sleep_tracking/data/drift_sleep_session_store.dart';
import 'package:sleepy3/features/sleep_tracking/data/sleepy3_database.dart';

void main() {
  group('DriftSettingsStore', () {
    late Sleepy3Database database;
    late DriftSettingsStore store;

    setUp(() {
      database = Sleepy3Database.forTesting(NativeDatabase.memory());
      store = DriftSettingsStore(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('defaults to system on an empty database', () async {
      expect(await store.loadThemeMode(), AppThemeMode.system);
    });

    test('round-trips every theme mode', () async {
      for (final mode in AppThemeMode.values) {
        await store.saveThemeMode(mode);
        expect(await store.loadThemeMode(), mode);
      }
    });

    test('overwrites the previous value', () async {
      await store.saveThemeMode(AppThemeMode.dark);
      await store.saveThemeMode(AppThemeMode.light);

      expect(await store.loadThemeMode(), AppThemeMode.light);
      final rows = await database.select(database.preferences).get();
      expect(rows, hasLength(1));
      expect(rows.single.settingKey, 'theme_mode');
      expect(rows.single.settingValue, 'light');
    });

    test('falls back to system for an unknown stored value', () async {
      await database
          .into(database.preferences)
          .insert(
            PreferencesCompanion.insert(
              settingKey: 'theme_mode',
              settingValue: 'sepia',
            ),
          );

      expect(await store.loadThemeMode(), AppThemeMode.system);
    });
  });

  test(
    'upgrading a v1 database preserves sessions and adds preferences',
    () async {
      final startedAt = DateTime(2026, 10, 20, 22, 30);
      final endedAt = startedAt.add(const Duration(hours: 7, minutes: 45));

      final database = Sleepy3Database.forTesting(
        NativeDatabase.memory(
          setup: (db) {
            db.execute('''
            CREATE TABLE sleep_sessions (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              started_at_millis INTEGER NOT NULL,
              ended_at_millis INTEGER NULL
            )
          ''');
            db.execute(
              'INSERT INTO sleep_sessions '
              '(started_at_millis, ended_at_millis) VALUES (?, ?)',
              [
                startedAt.millisecondsSinceEpoch,
                endedAt.millisecondsSinceEpoch,
              ],
            );
            db.userVersion = 1;
          },
        ),
      );
      addTearDown(database.close);

      final sessions = await DriftSleepSessionStore(database).load();
      expect(sessions.closedSessions, hasLength(1));
      expect(sessions.closedSessions.single.startedAt, startedAt);
      expect(sessions.closedSessions.single.endedAt, endedAt);

      final settings = DriftSettingsStore(database);
      expect(await settings.loadThemeMode(), AppThemeMode.system);
      await settings.saveThemeMode(AppThemeMode.dark);
      expect(await settings.loadThemeMode(), AppThemeMode.dark);
    },
  );
}
