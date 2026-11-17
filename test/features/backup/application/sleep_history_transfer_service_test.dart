import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/backup/application/sleep_history_transfer_service.dart';
import 'package:sleepy3/features/backup/domain/sleep_history_file.dart';
import 'package:sleepy3/features/health/data/drift_health_sync_store.dart';
import 'package:sleepy3/features/health/domain/sleep_data_source.dart';
import 'package:sleepy3/features/health/domain/stored_sleep_session.dart';
import 'package:sleepy3/features/sleep_tracking/data/drift_sleep_session_store.dart';
import 'package:sleepy3/features/sleep_tracking/data/sleepy3_database.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';

void main() {
  late Sleepy3Database database;
  late DriftSleepSessionStore sessions;
  late DriftHealthSyncStore sync;
  late SleepHistoryTransferService service;
  final now = DateTime(2026, 11, 16, 12);

  setUp(() {
    database = Sleepy3Database.forTesting(NativeDatabase.memory());
    sessions = DriftSleepSessionStore(database);
    sync = DriftHealthSyncStore(database);
    service = SleepHistoryTransferService(sessions, sync, () => now);
  });

  tearDown(() async {
    await database.close();
  });

  Future<SleepSession> addLocal(DateTime startedAt, DateTime endedAt) async {
    return sessions.insertClosedSession(
      SleepSession(startedAt: startedAt, endedAt: endedAt),
    );
  }

  Future<int> addDownloaded(
    DateTime startedAt,
    DateTime endedAt, {
    String? healthRecordId,
    String? sourceId = 'com.sec.android.app.shealth',
  }) {
    return sync.insertDownloaded(
      SleepSession(startedAt: startedAt, endedAt: endedAt, sourceId: sourceId),
      healthRecordId,
      now,
    );
  }

  SleepHistoryEntry entry(
    DateTime startedAt,
    DateTime endedAt, {
    bool isDownloaded = false,
    String? healthRecordId,
    String? healthClientRecordId,
    String? sourceId,
  }) {
    return SleepHistoryEntry(
      startedAt: startedAt,
      endedAt: endedAt,
      isDownloaded: isDownloaded,
      healthRecordId: healthRecordId,
      healthClientRecordId: healthClientRecordId,
      sourceId: sourceId,
    );
  }

  SleepHistoryFile fileWith(List<SleepHistoryEntry> entries) {
    return SleepHistoryFile(
      exportedAt: now,
      sessions: entries,
      invalidEntries: 0,
    );
  }

  test('exports the visible Local history with its provenance', () async {
    final local = await addLocal(
      DateTime(2026, 10, 20, 22),
      DateTime(2026, 10, 21, 7),
    );
    await addDownloaded(
      DateTime(2026, 10, 21, 22),
      DateTime(2026, 10, 22, 6),
      healthRecordId: 'record-1',
    );
    await sessions.startSession(
      SleepSession(startedAt: DateTime(2026, 10, 23)),
    );
    final visible = await sessions.loadClosedSessions();

    final export = service.exportHistory(
      visible,
      source: SleepDataSource.local,
    );

    expect(export.sessionCount, 2);
    final decoded = SleepHistoryFile.decode(export.contents);
    expect(decoded.sessions, hasLength(2));
    expect(decoded.sessions.first.startedAt, local.startedAt);
    expect(decoded.sessions.first.isDownloaded, isFalse);
    expect(decoded.sessions.last.isDownloaded, isTrue);
    expect(decoded.sessions.last.healthRecordId, 'record-1');
    expect(decoded.sessions.last.sourceId, 'com.sec.android.app.shealth');
  });

  test('exports the visible Google Health history as read-only copies', () {
    final startedAt = DateTime(2026, 10, 20, 22);
    final endedAt = DateTime(2026, 10, 21, 7);
    final visible = [
      SleepSession(
        startedAt: startedAt,
        endedAt: endedAt,
        healthRecordId: 'record-1',
        healthClientRecordId: 'sleepy3-1',
        sourceId: 'com.sleepy3.app',
      ),
      SleepSession(
        startedAt: startedAt.add(const Duration(days: 1)),
        endedAt: endedAt.add(const Duration(days: 1)),
        healthRecordId: 'record-2',
        sourceId: 'com.sec.android.app.shealth',
      ),
    ];

    final export = service.exportHistory(
      visible,
      source: SleepDataSource.healthConnect,
    );

    expect(export.sessionCount, 2);
    final decoded = SleepHistoryFile.decode(export.contents);
    expect(decoded.sessions.every((entry) => entry.isDownloaded), isTrue);
    expect(decoded.sessions.first.healthRecordId, 'record-1');
    expect(decoded.sessions.first.healthClientRecordId, 'sleepy3-1');
    expect(decoded.sessions.first.sourceId, 'com.sleepy3.app');
    expect(decoded.sessions.last.sourceId, 'com.sec.android.app.shealth');
  });

  test('exports an empty history without throwing', () {
    final export = service.exportHistory(
      const [],
      source: SleepDataSource.local,
    );

    expect(export.sessionCount, 0);
    expect(SleepHistoryFile.decode(export.contents).sessions, isEmpty);
  });

  test('previews new and duplicate sessions', () async {
    final existing = await addLocal(
      DateTime(2026, 10, 20, 22),
      DateTime(2026, 10, 21, 7),
    );
    await addDownloaded(
      DateTime(2026, 10, 21, 22),
      DateTime(2026, 10, 22, 6),
      healthRecordId: 'record-1',
    );

    final preview = await service.preview(
      fileWith([
        // Exact duplicate of the local row.
        entry(existing.startedAt, existing.endedAt!),
        // Health Connect id already stored, even with different times.
        entry(
          DateTime(2026, 9, 1, 22),
          DateTime(2026, 9, 2, 6),
          isDownloaded: true,
          healthRecordId: 'record-1',
        ),
        // New session.
        entry(DateTime(2026, 10, 22, 22), DateTime(2026, 10, 23, 7)),
      ]),
    );

    expect(preview.totalSessions, 3);
    expect(preview.newSessions, 1);
    expect(preview.duplicates, 2);
    expect(preview.invalidEntries, 0);
  });

  test('preview distinguishes local rows from read-only copies', () async {
    final preview = await service.preview(
      fileWith([
        entry(DateTime(2026, 10, 20, 22), DateTime(2026, 10, 21, 7)),
        entry(
          DateTime(2026, 10, 21, 22),
          DateTime(2026, 10, 22, 6),
          isDownloaded: true,
          healthRecordId: 'record-1',
        ),
      ]),
    );

    expect(preview.newSessions, 2);
    expect(preview.hasLocalSessions, isTrue);
    expect(preview.hasDownloadedSessions, isTrue);
  });

  test('a downloaded-only preview has no Add-able sessions', () async {
    final preview = await service.preview(
      fileWith([
        entry(
          DateTime(2026, 10, 20, 22),
          DateTime(2026, 10, 21, 7),
          isDownloaded: true,
        ),
      ]),
    );

    expect(preview.newSessions, 1);
    expect(preview.hasLocalSessions, isFalse);
    expect(preview.hasDownloadedSessions, isTrue);
  });

  test('counts duplicates inside the file itself', () async {
    final start = DateTime(2026, 10, 20, 22);
    final end = DateTime(2026, 10, 21, 7);
    final preview = await service.preview(
      fileWith([
        entry(start, end),
        entry(start, end),
        entry(start, end, healthRecordId: 'record-2'),
      ]),
    );

    expect(preview.newSessions, 1);
    expect(preview.duplicates, 2);
  });

  test('does not treat a matching client id as new', () async {
    final start = DateTime(2026, 10, 20, 22);
    final end = DateTime(2026, 10, 21, 7);
    await addDownloaded(DateTime(2026, 9, 1, 22), DateTime(2026, 9, 2, 6));
    final row = await database.select(database.sleepSessions).getSingle();
    await (database.update(
      database.sleepSessions,
    )..where((candidate) => candidate.id.equals(row.id))).write(
      SleepSessionsCompanion(healthClientRecordId: Value('sleepy3-1')),
    );

    final preview = await service.preview(
      fileWith([
        entry(start, end, healthClientRecordId: 'sleepy3-1'),
        entry(start, end),
      ]),
    );

    expect(preview.newSessions, 0);
    expect(preview.duplicates, 2);
  });

  test('imports local rows without Health Connect identity', () async {
    final preview = await service.preview(
      fileWith([
        entry(
          DateTime(2026, 10, 20, 22),
          DateTime(2026, 10, 21, 7),
          healthRecordId: 'record-1',
          healthClientRecordId: 'sleepy3-1',
        ),
      ]),
    );

    final result = await service.import(preview);

    expect(result.added, 1);
    expect(result.skipped, 0);
    expect(result.failed, 0);
    final row = await database.select(database.sleepSessions).getSingle();
    expect(row.origin, SleepSessionOrigin.local.storageValue);
    expect(row.healthRecordId, isNull);
    expect(row.healthClientRecordId, isNull);
    expect(row.healthSyncedAtMillis, isNull);
    expect(row.healthSyncSkipped, isFalse);
    expect(row.healthSyncBlocked, isTrue);
    expect(await sync.loadPendingUploads(), isEmpty);
    expect(await sync.loadBlockedUploads(), hasLength(1));
    expect(
      row.startedAtMillis,
      DateTime(2026, 10, 20, 22).millisecondsSinceEpoch,
    );
    expect(row.endedAtMillis, DateTime(2026, 10, 21, 7).millisecondsSinceEpoch);
  });

  test(
    'imports downloaded copies as read-only rows with their source',
    () async {
      final preview = await service.preview(
        fileWith([
          entry(
            DateTime(2026, 10, 20, 22),
            DateTime(2026, 10, 21, 7),
            isDownloaded: true,
            healthRecordId: 'record-1',
            sourceId: 'com.sec.android.app.shealth',
          ),
        ]),
      );

      final result = await service.import(preview);

      expect(result.added, 1);
      final row = await database.select(database.sleepSessions).getSingle();
      expect(row.origin, SleepSessionOrigin.healthConnect.storageValue);
      expect(row.healthRecordId, 'record-1');
      expect(row.sourceId, 'com.sec.android.app.shealth');
      expect(row.healthSyncedAtMillis, now.millisecondsSinceEpoch);
      expect(row.healthSyncBlocked, isFalse);

      final closed = await sessions.loadClosedSessions();
      expect(closed.single.isDownloaded, isTrue);
      expect(closed.single.isEditableLocal, isFalse);
    },
  );

  test('a second import adds nothing and duplicates the file', () async {
    final file = fileWith([
      entry(DateTime(2026, 10, 20, 22), DateTime(2026, 10, 21, 7)),
    ]);
    await service.import(await service.preview(file));

    final second = await service.preview(file);
    final result = await service.import(second);

    expect(second.newSessions, 0);
    expect(second.duplicates, 1);
    expect(result.added, 0);
    expect(await sessions.loadClosedSessions(), hasLength(1));
  });

  test('reports invalid entries as skipped', () async {
    final file = SleepHistoryFile(
      exportedAt: now,
      sessions: [entry(DateTime(2026, 10, 20, 22), DateTime(2026, 10, 21, 7))],
      invalidEntries: 2,
    );

    final preview = await service.preview(file);
    final result = await service.import(preview);

    expect(result.added, 1);
    expect(result.skipped, 2);
  });
}
