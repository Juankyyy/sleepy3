import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/sleep_tracking/domain/session_edit.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';

void main() {
  final now = DateTime(2026, 10, 21, 10);

  SleepSession closed(DateTime start, DateTime end) =>
      SleepSession(startedAt: start, endedAt: end);

  group('SessionEditDraft', () {
    test('starts with the session times and is clean', () {
      final session = closed(
        DateTime(2026, 10, 20, 23),
        DateTime(2026, 10, 21, 7),
      );

      final draft = SessionEditDraft.fromSession(session);

      expect(draft.startedAt, session.startedAt);
      expect(draft.endedAt, session.endedAt);
      expect(draft.duration, const Duration(hours: 8));
      expect(draft.isDirty, isFalse);
    });

    test('copyWith changes the duration and tracks whether it is dirty', () {
      final session = closed(
        DateTime(2026, 10, 20, 23),
        DateTime(2026, 10, 21, 7),
      );
      final draft = SessionEditDraft.fromSession(session);

      final changed = draft.copyWith(
        startedAt: DateTime(2026, 10, 20, 22),
        endedAt: DateTime(2026, 10, 21, 8),
      );

      expect(changed.duration, const Duration(hours: 10));
      expect(changed.isDirty, isTrue);
      expect(
        changed
            .copyWith(startedAt: session.startedAt, endedAt: session.endedAt)
            .isDirty,
        isFalse,
      );
    });

    test('rejects an open session', () {
      final open = SleepSession(startedAt: DateTime(2026, 10, 21, 9));

      expect(() => SessionEditDraft.fromSession(open), throwsArgumentError);
    });
  });

  group('validateSessionEdit', () {
    test('accepts a valid draft', () {
      final draft = SessionEditDraft(
        startedAt: DateTime(2026, 10, 20, 23),
        endedAt: DateTime(2026, 10, 21, 7),
      );

      expect(
        validateSessionEdit(
          draft: draft,
          now: now,
          otherClosedSessions: [
            closed(DateTime(2026, 10, 19, 23), DateTime(2026, 10, 20, 7)),
          ],
          openSession: SleepSession(startedAt: DateTime(2026, 10, 21, 9)),
        ),
        isEmpty,
      );
    });

    test('requires the wake time to be after the sleep time', () {
      final sameTime = SessionEditDraft(
        startedAt: DateTime(2026, 10, 21, 7),
        endedAt: DateTime(2026, 10, 21, 7),
      );
      final reversed = SessionEditDraft(
        startedAt: DateTime(2026, 10, 21, 7),
        endedAt: DateTime(2026, 10, 21, 6),
      );

      expect(validateSessionEdit(draft: sameTime, now: now), [
        SessionEditError.endNotAfterStart,
      ]);
      expect(validateSessionEdit(draft: reversed, now: now), [
        SessionEditError.endNotAfterStart,
      ]);
    });

    test('rejects times in the future', () {
      final futureStart = SessionEditDraft(
        startedAt: DateTime(2026, 10, 21, 11),
        endedAt: DateTime(2026, 10, 21, 12),
      );
      final futureEnd = SessionEditDraft(
        startedAt: DateTime(2026, 10, 21, 9),
        endedAt: DateTime(2026, 10, 21, 10, 5),
      );

      expect(validateSessionEdit(draft: futureStart, now: now), [
        SessionEditError.startInTheFuture,
        SessionEditError.endInTheFuture,
      ]);
      expect(validateSessionEdit(draft: futureEnd, now: now), [
        SessionEditError.endInTheFuture,
      ]);
    });

    test('rejects overlaps with another closed session', () {
      final other = closed(
        DateTime(2026, 10, 20, 22),
        DateTime(2026, 10, 21, 7),
      );

      for (final draft in [
        // Starts before and ends inside.
        SessionEditDraft(
          startedAt: DateTime(2026, 10, 20, 21),
          endedAt: DateTime(2026, 10, 20, 23),
        ),
        // Fully contained.
        SessionEditDraft(
          startedAt: DateTime(2026, 10, 21, 1),
          endedAt: DateTime(2026, 10, 21, 2),
        ),
        // Contains the other session.
        SessionEditDraft(
          startedAt: DateTime(2026, 10, 20, 21),
          endedAt: DateTime(2026, 10, 21, 8),
        ),
      ]) {
        expect(
          validateSessionEdit(
            draft: draft,
            now: now,
            otherClosedSessions: [other],
          ),
          [SessionEditError.overlapsClosedSession],
        );
      }
    });

    test('allows sessions that only touch at an endpoint', () {
      final before = SessionEditDraft(
        startedAt: DateTime(2026, 10, 20, 21),
        endedAt: DateTime(2026, 10, 20, 22),
      );
      final after = SessionEditDraft(
        startedAt: DateTime(2026, 10, 21, 7),
        endedAt: DateTime(2026, 10, 21, 8),
      );

      final others = [
        closed(DateTime(2026, 10, 20, 22), DateTime(2026, 10, 21, 7)),
      ];

      expect(
        validateSessionEdit(
          draft: before,
          now: now,
          otherClosedSessions: others,
        ),
        isEmpty,
      );
      expect(
        validateSessionEdit(
          draft: after,
          now: now,
          otherClosedSessions: others,
        ),
        isEmpty,
      );
    });

    test('rejects an overlap with the open session', () {
      final open = SleepSession(startedAt: DateTime(2026, 10, 21, 9));
      final overlapping = SessionEditDraft(
        startedAt: DateTime(2026, 10, 21, 8),
        endedAt: DateTime(2026, 10, 21, 9, 30),
      );
      final touching = SessionEditDraft(
        startedAt: DateTime(2026, 10, 21, 7),
        endedAt: DateTime(2026, 10, 21, 9),
      );

      expect(
        validateSessionEdit(draft: overlapping, now: now, openSession: open),
        [SessionEditError.overlapsOpenSession],
      );
      expect(
        validateSessionEdit(draft: touching, now: now, openSession: open),
        isEmpty,
      );
    });

    test('exposes English messages for every rule', () {
      for (final error in SessionEditError.values) {
        expect(error.message, isNotEmpty);
      }
    });
  });

  group('sessionEditAccess', () {
    test('edits local rows and keeps downloaded copies read-only', () {
      final local = SleepSession(
        startedAt: DateTime(2026, 10, 20, 23),
        endedAt: DateTime(2026, 10, 21, 7),
        localId: 7,
      );
      final downloaded = SleepSession(
        startedAt: DateTime(2026, 10, 20, 23),
        endedAt: DateTime(2026, 10, 21, 7),
        localId: 8,
        isDownloaded: true,
        healthRecordId: 'uuid',
        sourceId: 'com.example.other',
      );

      expect(
        sessionEditAccess(local, healthConnectSource: false),
        SessionEditAccess.editAndDelete,
      );
      expect(
        sessionEditAccess(downloaded, healthConnectSource: false),
        SessionEditAccess.readOnly,
      );
      expect(
        sessionEditAccess(
          SleepSession(
            startedAt: DateTime(2026, 10, 20, 23),
            endedAt: DateTime(2026, 10, 21, 7),
          ),
          healthConnectSource: false,
        ),
        SessionEditAccess.readOnly,
      );
    });

    test('edits own Health Connect records only when a local copy exists', () {
      final ownRecord = SleepSession(
        startedAt: DateTime(2026, 10, 20, 23),
        endedAt: DateTime(2026, 10, 21, 7),
        healthRecordId: 'uuid',
        sourceId: 'com.sleepy3.app',
      );
      final withLocalCopy = SleepSession(
        startedAt: DateTime(2026, 10, 20, 23),
        endedAt: DateTime(2026, 10, 21, 7),
        localId: 9,
        isDownloaded: true,
        healthRecordId: 'uuid',
        healthClientRecordId: 'sleepy3-1',
        sourceId: 'com.sleepy3.app',
      );
      final localCopyWithoutClientId = SleepSession(
        startedAt: DateTime(2026, 10, 20, 23),
        endedAt: DateTime(2026, 10, 21, 7),
        localId: 10,
        isDownloaded: true,
        healthRecordId: 'uuid',
        sourceId: 'com.sleepy3.app',
      );

      expect(
        sessionEditAccess(
          ownRecord,
          healthConnectSource: true,
          isOwnHealthRecord: true,
        ),
        SessionEditAccess.deleteOnly,
      );
      expect(
        sessionEditAccess(
          withLocalCopy,
          healthConnectSource: true,
          isOwnHealthRecord: true,
        ),
        SessionEditAccess.editAndDelete,
      );
      expect(
        sessionEditAccess(
          localCopyWithoutClientId,
          healthConnectSource: true,
          isOwnHealthRecord: true,
        ),
        SessionEditAccess.deleteOnly,
      );
    });

    test('keeps other apps and unidentifiable records read-only', () {
      final otherApp = SleepSession(
        startedAt: DateTime(2026, 10, 20, 23),
        endedAt: DateTime(2026, 10, 21, 7),
        localId: 9,
        healthRecordId: 'uuid',
        healthClientRecordId: 'other-1',
        sourceId: 'com.example.other',
      );
      final unidentified = SleepSession(
        startedAt: DateTime(2026, 10, 20, 23),
        endedAt: DateTime(2026, 10, 21, 7),
        sourceId: 'com.sleepy3.app',
      );

      expect(
        sessionEditAccess(
          otherApp,
          healthConnectSource: true,
          isOwnHealthRecord: false,
        ),
        SessionEditAccess.readOnly,
      );
      expect(
        sessionEditAccess(
          unidentified,
          healthConnectSource: true,
          isOwnHealthRecord: true,
        ),
        SessionEditAccess.readOnly,
      );
    });

    test('never edits an open session', () {
      final open = SleepSession(
        startedAt: DateTime(2026, 10, 21, 9),
        localId: 3,
      );

      expect(
        sessionEditAccess(open, healthConnectSource: false),
        SessionEditAccess.readOnly,
      );
    });
  });
}
