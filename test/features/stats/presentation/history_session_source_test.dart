import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/health/domain/sleep_data_source.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';
import 'package:sleepy3/features/stats/presentation/history_session_source.dart';

void main() {
  SleepSession session({String? sourceId, bool isDownloaded = false}) {
    return SleepSession(
      startedAt: DateTime(2026, 10, 20, 22),
      endedAt: DateTime(2026, 10, 21, 6),
      isDownloaded: isDownloaded,
      sourceId: sourceId,
    );
  }

  group('Local mode', () {
    test('a local session is Sleepy3\'s own', () {
      expect(
        isSessionFromAnotherApp(session(), SleepDataSource.local),
        isFalse,
      );
    });

    test('an uploaded session is still Sleepy3\'s own', () {
      expect(
        isSessionFromAnotherApp(
          session(sourceId: 'com.sleepy3.app'),
          SleepDataSource.local,
        ),
        isFalse,
      );
    });

    test('a downloaded copy from another app belongs to that app', () {
      expect(
        isSessionFromAnotherApp(
          session(sourceId: 'com.example.watch', isDownloaded: true),
          SleepDataSource.local,
        ),
        isTrue,
      );
    });

    test('a downloaded copy of a Sleepy3 record is still Sleepy3\'s', () {
      expect(
        isSessionFromAnotherApp(
          session(sourceId: 'com.sleepy3.app', isDownloaded: true),
          SleepDataSource.local,
        ),
        isFalse,
      );
    });

    test('a downloaded copy without a source id counts as another app', () {
      expect(
        isSessionFromAnotherApp(
          session(isDownloaded: true),
          SleepDataSource.local,
        ),
        isTrue,
      );
    });
  });

  group('Google Health mode', () {
    test('a Sleepy3 record is its own', () {
      expect(
        isSessionFromAnotherApp(
          session(sourceId: 'com.sleepy3.app'),
          SleepDataSource.healthConnect,
        ),
        isFalse,
      );
    });

    test('a record from another app is marked', () {
      expect(
        isSessionFromAnotherApp(
          session(sourceId: 'com.example.watch'),
          SleepDataSource.healthConnect,
        ),
        isTrue,
      );
    });

    test('a record without a source id counts as another app', () {
      expect(
        isSessionFromAnotherApp(session(), SleepDataSource.healthConnect),
        isTrue,
      );
    });
  });
}
