import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/health/domain/sleep_data_source.dart';
import 'package:sleepy3/features/reminders/domain/sleep_reminder.dart';
import 'package:sleepy3/features/settings/data/drift_settings_store.dart';
import 'package:sleepy3/features/settings/domain/app_language.dart';
import 'package:sleepy3/features/settings/domain/app_theme_mode.dart';
import 'package:sleepy3/features/settings/domain/app_time_format.dart';
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

    test('has no saved time format on an empty database', () async {
      expect(await store.loadTimeFormat(), isNull);
    });

    test('round-trips every time format', () async {
      for (final format in AppTimeFormat.values) {
        await store.saveTimeFormat(format);
        expect(await store.loadTimeFormat(), format);
      }
    });

    test('stores the time format under time_format', () async {
      await store.saveTimeFormat(AppTimeFormat.twentyFourHour);

      final rows = await database.select(database.preferences).get();
      expect(rows, hasLength(1));
      expect(rows.single.settingKey, 'time_format');
      expect(rows.single.settingValue, 'twentyFourHour');
    });

    test('returns null for an unknown stored time format', () async {
      await database
          .into(database.preferences)
          .insert(
            PreferencesCompanion.insert(
              settingKey: 'time_format',
              settingValue: 'military',
            ),
          );

      expect(await store.loadTimeFormat(), isNull);
    });

    test('has no saved language on an empty database', () async {
      expect(await store.loadLanguage(), isNull);
    });

    test('round-trips every language', () async {
      for (final language in AppLanguage.values) {
        await store.saveLanguage(language);
        expect(await store.loadLanguage(), language);
      }
    });

    test('stores the language under language', () async {
      await store.saveLanguage(AppLanguage.spanish);

      final rows = await database.select(database.preferences).get();
      expect(rows, hasLength(1));
      expect(rows.single.settingKey, 'language');
      expect(rows.single.settingValue, 'spanish');
    });

    test('returns null for an unknown stored language', () async {
      await database
          .into(database.preferences)
          .insert(
            PreferencesCompanion.insert(
              settingKey: 'language',
              settingValue: 'french',
            ),
          );

      expect(await store.loadLanguage(), isNull);
    });

    test('defaults to Local on an empty database', () async {
      expect(await store.loadSleepDataSource(), SleepDataSource.local);
    });

    test('round-trips every sleep data source', () async {
      for (final source in SleepDataSource.values) {
        await store.saveSleepDataSource(source);
        expect(await store.loadSleepDataSource(), source);
      }
    });

    test('falls back to Local for an unknown source value', () async {
      await database
          .into(database.preferences)
          .insert(
            PreferencesCompanion.insert(
              settingKey: 'sleep_data_source',
              settingValue: 'cloud',
            ),
          );

      expect(await store.loadSleepDataSource(), SleepDataSource.local);
    });

    test('defaults to a disabled 22:00 reminder', () async {
      expect(await store.loadSleepReminder(), SleepReminder.defaults);
    });

    test('round-trips an enabled reminder', () async {
      const reminder = SleepReminder(enabled: true, hour: 23, minute: 15);

      await store.saveSleepReminder(reminder);

      expect(await store.loadSleepReminder(), reminder);
    });

    test('stores the reminder under its two preference keys', () async {
      await store.saveSleepReminder(
        const SleepReminder(enabled: true, hour: 7, minute: 5),
      );

      final rows = await database.select(database.preferences).get();
      expect(
        {for (final row in rows) row.settingKey: row.settingValue},
        {'sleep_reminder_enabled': 'true', 'sleep_reminder_time': '07:05'},
      );
    });

    test('falls back to 22:00 for a malformed stored time', () async {
      await database
          .into(database.preferences)
          .insert(
            PreferencesCompanion.insert(
              settingKey: 'sleep_reminder_time',
              settingValue: 'late',
            ),
          );

      final reminder = await store.loadSleepReminder();

      expect(reminder.enabled, isFalse);
      expect(reminder.hour, 22);
      expect(reminder.minute, 0);
    });

    test('keeps a valid time when the enabled key is missing', () async {
      await database
          .into(database.preferences)
          .insert(
            PreferencesCompanion.insert(
              settingKey: 'sleep_reminder_time',
              settingValue: '21:30',
            ),
          );

      final reminder = await store.loadSleepReminder();

      expect(reminder.enabled, isFalse);
      expect(reminder.hour, 21);
      expect(reminder.minute, 30);
    });

    test(
      'defaults to not having asked for the sleep notification permission',
      () async {
        expect(await store.loadSleepNotificationPermissionAsked(), isFalse);
      },
    );

    test('round-trips the sleep notification permission flag', () async {
      await store.saveSleepNotificationPermissionAsked(true);

      expect(await store.loadSleepNotificationPermissionAsked(), isTrue);
      final rows = await database.select(database.preferences).get();
      expect(rows, hasLength(1));
      expect(rows.single.settingKey, 'sleep_notification_permission_asked');
      expect(rows.single.settingValue, 'true');
    });

    test('defaults to showing the sleep status notification', () async {
      expect(await store.loadSleepingNotificationEnabled(), isTrue);
    });

    test('round-trips the sleep status notification setting', () async {
      await store.saveSleepingNotificationEnabled(false);

      expect(await store.loadSleepingNotificationEnabled(), isFalse);
      final rows = await database.select(database.preferences).get();
      expect(rows, hasLength(1));
      expect(rows.single.settingKey, 'sleep_status_notification_enabled');
      expect(rows.single.settingValue, 'false');

      await store.saveSleepingNotificationEnabled(true);
      expect(await store.loadSleepingNotificationEnabled(), isTrue);
    });

    test('stores the theme and the source side by side', () async {
      await store.saveThemeMode(AppThemeMode.dark);
      await store.saveSleepDataSource(SleepDataSource.healthConnect);

      final rows = await database.select(database.preferences).get();
      expect(rows, hasLength(2));
      expect(
        {for (final row in rows) row.settingKey: row.settingValue},
        {'theme_mode': 'dark', 'sleep_data_source': 'healthConnect'},
      );
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
