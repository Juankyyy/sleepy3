import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';

void main() {
  test('finish preserves the local and Health Connect metadata', () {
    final startedAt = DateTime(2026, 10, 20, 23);
    final endedAt = DateTime(2026, 10, 21, 7);
    final session = SleepSession(
      startedAt: startedAt,
      localId: 7,
      isDownloaded: true,
      healthRecordId: 'uuid',
      healthClientRecordId: 'sleepy3-1',
      sourceId: 'com.sleepy3.app',
    );

    final finished = session.finish(endedAt);

    expect(finished.startedAt, startedAt);
    expect(finished.endedAt, endedAt);
    expect(finished.localId, 7);
    expect(finished.isDownloaded, isTrue);
    expect(finished.healthRecordId, 'uuid');
    expect(finished.healthClientRecordId, 'sleepy3-1');
    expect(finished.sourceId, 'com.sleepy3.app');
    expect(finished.isOpen, isFalse);
  });

  test('only local rows that were not downloaded are editable locally', () {
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
    );
    final healthOnly = SleepSession(
      startedAt: DateTime(2026, 10, 20, 23),
      endedAt: DateTime(2026, 10, 21, 7),
      healthRecordId: 'uuid',
      sourceId: 'com.sleepy3.app',
    );

    expect(local.isEditableLocal, isTrue);
    expect(downloaded.isEditableLocal, isFalse);
    expect(healthOnly.isEditableLocal, isFalse);
  });

  test('hasSameIdentityAs prefers the local row id', () {
    final first = SleepSession(
      startedAt: DateTime(2026, 10, 20, 23),
      endedAt: DateTime(2026, 10, 21, 7),
      localId: 7,
      healthRecordId: 'first-record',
    );
    final second = SleepSession(
      startedAt: DateTime(2026, 10, 20, 23),
      endedAt: DateTime(2026, 10, 21, 7),
      localId: 7,
      healthRecordId: 'second-record',
    );

    expect(first.hasSameIdentityAs(second), isTrue);
  });

  test('hasSameIdentityAs falls back to the Health Connect record id', () {
    final localCopy = SleepSession(
      startedAt: DateTime(2026, 10, 20, 23),
      endedAt: DateTime(2026, 10, 21, 7),
      localId: 7,
      healthRecordId: 'record-1',
    );
    final healthRecord = SleepSession(
      startedAt: DateTime(2026, 10, 20, 23),
      endedAt: DateTime(2026, 10, 21, 7),
      healthRecordId: 'record-1',
      sourceId: 'com.sleepy3.app',
    );
    final otherRecord = SleepSession(
      startedAt: DateTime(2026, 10, 20, 23),
      endedAt: DateTime(2026, 10, 21, 7),
      healthRecordId: 'record-2',
    );

    expect(localCopy.hasSameIdentityAs(healthRecord), isTrue);
    expect(localCopy.hasSameIdentityAs(otherRecord), isFalse);
  });

  test('withTimes keeps the identity and origin metadata', () {
    final session = SleepSession(
      startedAt: DateTime(2026, 10, 20, 23),
      endedAt: DateTime(2026, 10, 21, 7),
      localId: 7,
      isDownloaded: true,
      healthRecordId: 'uuid',
      healthClientRecordId: 'sleepy3-1',
      sourceId: 'com.sleepy3.app',
    );
    final newStart = DateTime(2026, 10, 20, 22);
    final newEnd = DateTime(2026, 10, 21, 8);

    final updated = session.withTimes(newStart, newEnd);

    expect(updated.startedAt, newStart);
    expect(updated.endedAt, newEnd);
    expect(updated.localId, 7);
    expect(updated.isDownloaded, isTrue);
    expect(updated.healthRecordId, 'uuid');
    expect(updated.healthClientRecordId, 'sleepy3-1');
    expect(updated.sourceId, 'com.sleepy3.app');
  });
}
