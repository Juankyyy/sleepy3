import '../../health/domain/sleep_data_source.dart';
import '../../health/domain/sleepy3_health_source.dart';
import '../../sleep_tracking/domain/sleep_session.dart';

/// Whether [session] was written by an app other than Sleepy3.
///
/// Google Health mode lists every record in Health Connect, so a session comes
/// from another app when its writer package is not one of Sleepy3's. Local mode
/// only reads Drift, where downloaded copies are the only rows written by
/// another app; sessions Sleepy3 uploaded keep their own local row.
///
/// A downloaded copy of a Sleepy3 record is still Sleepy3's, even though Local
/// mode keeps it read-only, so it does not count as another app.
bool isSessionFromAnotherApp(SleepSession session, SleepDataSource source) {
  if (source == SleepDataSource.healthConnect) {
    return !isSleepy3HealthRecord(session.sourceId);
  }
  return session.isDownloaded && !isSleepy3HealthRecord(session.sourceId);
}
