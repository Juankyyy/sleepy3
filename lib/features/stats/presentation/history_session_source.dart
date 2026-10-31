import '../../health/domain/sleep_data_source.dart';
import '../../sleep_tracking/domain/sleep_session.dart';

/// Where a history row came from, as shown by its leading source icon.
///
/// This is not `SleepSessionOrigin`: that enum records how a Drift row was
/// stored, while this one groups sessions by the place the user knows them
/// from. A session that was sent to Google Health counts as Google Health even
/// when Sleepy3 created it.
enum HistorySessionSource {
  /// The session only exists in Sleepy3's local database.
  local,

  /// The session was sent to or read from Google Health.
  googleHealth,
}

/// The provenance of [session] in the selected [source].
///
/// In Local mode a session becomes Google Health as soon as it has a Health
/// Connect record, whether Sleepy3 uploaded it or it was downloaded. In Google
/// Health mode every visible row comes from Health Connect, so all of them are
/// Google Health, including records written by Sleepy3.
HistorySessionSource historySessionSource(
  SleepSession session,
  SleepDataSource source,
) {
  if (source == SleepDataSource.healthConnect) {
    return HistorySessionSource.googleHealth;
  }
  if (session.isDownloaded || session.healthRecordId != null) {
    return HistorySessionSource.googleHealth;
  }
  return HistorySessionSource.local;
}

/// Short label for the source tooltip and the spoken row label.
String historySessionSourceLabel(HistorySessionSource source) {
  return switch (source) {
    HistorySessionSource.local => 'Local',
    HistorySessionSource.googleHealth => 'Google Health',
  };
}
