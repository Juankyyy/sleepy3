import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'sleepy3_database.g.dart';

/// Session rows. Timestamps are stored as Unix milliseconds so the exact
/// local time survives a round-trip; Drift's DateTime columns would depend on
/// its timezone mapping.
@DataClassName('SleepSessionRow')
class SleepSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get startedAtMillis => integer()();
  IntColumn get endedAtMillis => integer().nullable()();
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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // v2 adds the preferences table. Existing sessions are untouched.
      if (from < 2) {
        await m.createTable(preferences);
      }
    },
  );
}
