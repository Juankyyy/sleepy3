import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/health/domain/sleep_data_source.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';
import 'package:sleepy3/features/stats/presentation/history_session_source.dart';

void main() {
  SleepSession session({
    String? healthRecordId,
    bool isDownloaded = false,
    String? sourceId,
  }) {
    return SleepSession(
      startedAt: DateTime(2026, 10, 20, 22),
      endedAt: DateTime(2026, 10, 21, 6),
      healthRecordId: healthRecordId,
      isDownloaded: isDownloaded,
      sourceId: sourceId,
    );
  }

  group('Local mode', () {
    test('a session without a Health Connect record is local', () {
      expect(
        historySessionSource(session(), SleepDataSource.local),
        HistorySessionSource.local,
      );
    });

    test('an uploaded session is Google Health', () {
      expect(
        historySessionSource(
          session(healthRecordId: 'health-1'),
          SleepDataSource.local,
        ),
        HistorySessionSource.googleHealth,
      );
    });

    test('a downloaded session is Google Health', () {
      expect(
        historySessionSource(
          session(healthRecordId: 'health-1', isDownloaded: true),
          SleepDataSource.local,
        ),
        HistorySessionSource.googleHealth,
      );
    });
  });

  group('Google Health mode', () {
    test('a Sleepy3 record read from Google Health is Google Health', () {
      expect(
        historySessionSource(
          session(healthRecordId: 'health-1', sourceId: 'com.sleepy3.app'),
          SleepDataSource.healthConnect,
        ),
        HistorySessionSource.googleHealth,
      );
    });

    test('a record from another app is Google Health', () {
      expect(
        historySessionSource(
          session(healthRecordId: 'health-2', sourceId: 'com.example.watch'),
          SleepDataSource.healthConnect,
        ),
        HistorySessionSource.googleHealth,
      );
    });
  });

  test('labels the two sources for tooltips and screen readers', () {
    expect(historySessionSourceLabel(HistorySessionSource.local), 'Local');
    expect(
      historySessionSourceLabel(HistorySessionSource.googleHealth),
      'Google Health',
    );
  });
}
