import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'sleepy3_database.g.dart';

/// Session rows. Timestamps are stored as Unix milliseconds so the exact
/// local time survives a round-trip; Drift's DateTime columns would depend on
/// its timezone mapping.
///
/// `health_record_id` is unique when present so a Health Connect record can be
/// downloaded once. SQLite allows any number of nulls in a unique index, which
/// is what local rows keep until they are uploaded.
@DataClassName('SleepSessionRow')
@TableIndex(
  name: 'sleep_sessions_health_record_id',
  columns: {#healthRecordId},
  unique: true,
)
class SleepSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get startedAtMillis => integer()();
  IntColumn get endedAtMillis => integer().nullable()();

  /// Health Connect UUID once the record is uploaded or downloaded.
  TextColumn get healthRecordId => text().nullable()();

  /// When the record was last uploaded to or downloaded from Health Connect.
  IntColumn get healthSyncedAtMillis => integer().nullable()();

  /// Set when the session is not eligible for upload, such as a zero duration.
  BoolColumn get healthSyncSkipped =>
      boolean().withDefault(const Constant(false))();

  /// `local` for sessions started in Sleepy3, `healthConnect` for downloads.
  TextColumn get origin => text().withDefault(const Constant('local'))();
}

/// App-wide key/value preferences. Keys are stable strings so future settings
/// can be added without another table migration.
@DataClassName('PreferenceRow')
class Preferences extends Table {
  TextColumn get settingKey => text()();
  TextColumn get settingValue => text()();

  @override
  Set<Column> get primaryKey => {settingKey};
}

@DriftDatabase(tables: [SleepSessions, Preferences])
class Sleepy3Database extends _$Sleepy3Database {
  Sleepy3Database() : super(driftDatabase(name: 'sleepy3'));

  /// Used by tests with an in-memory database.
  Sleepy3Database.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // v2 adds the preferences table. Existing sessions are untouched.
      if (from < 2) {
        await m.createTable(preferences);
      }
      // v3 adds the Health Connect metadata. Existing rows stay local,
      // unsynced and eligible for upload.
      if (from < 3) {
        await m.addColumn(sleepSessions, sleepSessions.healthRecordId);
        await m.addColumn(sleepSessions, sleepSessions.healthSyncedAtMillis);
        await m.addColumn(sleepSessions, sleepSessions.healthSyncSkipped);
        await m.addColumn(sleepSessions, sleepSessions.origin);
        await m.createIndex(sleepSessionsHealthRecordId);
      }
    },
  );
}
