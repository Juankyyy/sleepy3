import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/backup/domain/sleep_history_file.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';

void main() {
  group('SleepHistoryFile codec', () {
    test('round-trips exact times and Health Connect metadata', () {
      final startedAt = DateTime(2026, 10, 20, 22, 30, 15, 123);
      final endedAt = DateTime(2026, 10, 21, 7, 15, 45, 678);
      final file = SleepHistoryFile.fromSessions([
        SleepSession(
          startedAt: startedAt,
          endedAt: endedAt,
          isDownloaded: true,
          healthRecordId: 'record-1',
          healthClientRecordId: 'sleepy3-1',
          sourceId: 'com.sec.android.app.shealth',
        ),
      ], exportedAt: DateTime.utc(2026, 11, 16, 12));

      final decoded = SleepHistoryFile.decode(file.encode());

      expect(decoded.exportedAt, DateTime.utc(2026, 11, 16, 12));
      expect(decoded.sessions, hasLength(1));
      final entry = decoded.sessions.single;
      expect(
        entry.startedAt.millisecondsSinceEpoch,
        startedAt.millisecondsSinceEpoch,
      );
      expect(
        entry.endedAt.millisecondsSinceEpoch,
        endedAt.millisecondsSinceEpoch,
      );
      expect(entry.isDownloaded, isTrue);
      expect(entry.healthRecordId, 'record-1');
      expect(entry.healthClientRecordId, 'sleepy3-1');
      expect(entry.sourceId, 'com.sec.android.app.shealth');
      expect(decoded.invalidEntries, 0);
    });

    test('writes a versioned, indented JSON document', () {
      final file = SleepHistoryFile.fromSessions([
        SleepSession(
          startedAt: DateTime(2026, 10, 20, 22),
          endedAt: DateTime(2026, 10, 21, 7),
        ),
      ], exportedAt: DateTime.utc(2026, 11, 16, 12));

      final encoded = file.encode();
      final payload = jsonDecode(encoded) as Map<String, dynamic>;

      expect(payload['format'], sleepHistoryFileFormat);
      expect(payload['version'], sleepHistoryFileVersion);
      expect(payload['exportedAt'], '2026-11-16T12:00:00.000Z');
      expect(encoded, contains('\n  '));
      final sessions = payload['sessions'] as List;
      expect(sessions.single['origin'], 'local');
      expect(sessions.single['startedAtMillis'], isA<int>());
    });

    test('markAsDownloaded marks every entry as a Health Connect copy', () {
      final file = SleepHistoryFile.fromSessions(
        [
          SleepSession(
            startedAt: DateTime(2026, 10, 20, 22),
            endedAt: DateTime(2026, 10, 21, 7),
            healthRecordId: 'record-1',
          ),
        ],
        exportedAt: DateTime.utc(2026, 11, 16, 12),
        markAsDownloaded: true,
      );

      expect(file.sessions.single.isDownloaded, isTrue);
      expect(file.encode(), contains('"origin": "healthConnect"'));
    });

    test('sorts sessions oldest first', () {
      final later = SleepSession(
        startedAt: DateTime(2026, 10, 22, 22),
        endedAt: DateTime(2026, 10, 23, 7),
      );
      final earlier = SleepSession(
        startedAt: DateTime(2026, 10, 20, 22),
        endedAt: DateTime(2026, 10, 21, 7),
      );

      final file = SleepHistoryFile.fromSessions([
        later,
        earlier,
      ], exportedAt: DateTime(2026, 11, 16));

      expect(file.sessions.first.startedAt, earlier.startedAt);
      expect(file.sessions.last.startedAt, later.startedAt);
    });

    test('skips the open session when building an export', () {
      final file = SleepHistoryFile.fromSessions([
        SleepSession(startedAt: DateTime(2026, 10, 22, 23)),
      ], exportedAt: DateTime(2026, 11, 16));

      expect(file.sessions, isEmpty);
    });

    test('throws unreadable for invalid JSON', () {
      expect(
        () => SleepHistoryFile.decode('{not json'),
        throwsA(
          isA<SleepHistoryFileException>().having(
            (error) => error.error,
            'error',
            SleepHistoryFileError.unreadable,
          ),
        ),
      );
    });

    test('throws notSleepy3 for another format', () {
      expect(
        () => SleepHistoryFile.decode(
          '{"format":"other","version":1,"sessions":[]}',
        ),
        throwsA(
          isA<SleepHistoryFileException>().having(
            (error) => error.error,
            'error',
            SleepHistoryFileError.notSleepy3,
          ),
        ),
      );
      expect(
        () => SleepHistoryFile.decode('[]'),
        throwsA(
          isA<SleepHistoryFileException>().having(
            (error) => error.error,
            'error',
            SleepHistoryFileError.notSleepy3,
          ),
        ),
      );
    });

    test('rejects an unknown newer version', () {
      expect(
        () => SleepHistoryFile.decode(
          '{"format":"$sleepHistoryFileFormat","version":2,"sessions":[]}',
        ),
        throwsA(
          isA<SleepHistoryFileException>().having(
            (error) => error.error,
            'error',
            SleepHistoryFileError.newerVersion,
          ),
        ),
      );
    });

    test('accepts an empty session list', () {
      final file = SleepHistoryFile.decode(
        '{"format":"$sleepHistoryFileFormat","version":1,"sessions":[]}',
      );

      expect(file.sessions, isEmpty);
      expect(file.invalidEntries, 0);
      expect(file.exportedAt, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('counts unreadable and out-of-range entries as invalid', () {
      final start = DateTime(2026, 10, 20, 22).millisecondsSinceEpoch;
      final end = DateTime(2026, 10, 21, 7).millisecondsSinceEpoch;
      final json = jsonEncode({
        'format': sleepHistoryFileFormat,
        'version': 1,
        'sessions': [
          {'startedAtMillis': start, 'endedAtMillis': end},
          {'startedAtMillis': end, 'endedAtMillis': start},
          {'startedAtMillis': start},
          {'startedAtMillis': 'start', 'endedAtMillis': end},
          // 5 minutes: shorter than the recordable minimum.
          {'startedAtMillis': start, 'endedAtMillis': start + 5 * 60 * 1000},
          // 24 hours: outside the recordable maximum.
          {
            'startedAtMillis': start,
            'endedAtMillis': start + 24 * 60 * 60 * 1000,
          },
        ],
      });

      final file = SleepHistoryFile.decode(json);

      expect(file.sessions, hasLength(1));
      expect(file.invalidEntries, 5);
    });

    test('accepts a downloaded copy outside the recordable range', () {
      final start = DateTime(2026, 10, 20, 22).millisecondsSinceEpoch;
      final end = start + 5 * 60 * 1000;
      final json = jsonEncode({
        'format': sleepHistoryFileFormat,
        'version': 1,
        'sessions': [
          {
            'startedAtMillis': start,
            'endedAtMillis': end,
            'origin': 'healthConnect',
            'sourceId': 'com.sec.android.app.shealth',
          },
        ],
      });

      final file = SleepHistoryFile.decode(json);

      expect(file.sessions, hasLength(1));
      expect(file.invalidEntries, 0);
      expect(file.sessions.single.isDownloaded, isTrue);
      expect(file.sessions.single.sourceId, 'com.sec.android.app.shealth');
    });

    test('normalizes blank ids to null', () {
      final start = DateTime(2026, 10, 20, 22).millisecondsSinceEpoch;
      final end = DateTime(2026, 10, 21, 7).millisecondsSinceEpoch;
      final json = jsonEncode({
        'format': sleepHistoryFileFormat,
        'version': 1,
        'sessions': [
          {
            'startedAtMillis': start,
            'endedAtMillis': end,
            'healthRecordId': '   ',
            'healthClientRecordId': '',
            'sourceId': ' com.sec.android.app.shealth ',
          },
        ],
      });

      final entry = SleepHistoryFile.decode(json).sessions.single;

      expect(entry.healthRecordId, isNull);
      expect(entry.healthClientRecordId, isNull);
      expect(entry.sourceId, 'com.sec.android.app.shealth');
    });
  });
}
