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

@DriftDatabase(tables: [SleepSessions])
class Sleepy3Database extends _$Sleepy3Database {
  Sleepy3Database() : super(driftDatabase(name: 'sleepy3'));

  /// Used by tests with an in-memory database.
  Sleepy3Database.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(onCreate: (m) => m.createAll());
}
