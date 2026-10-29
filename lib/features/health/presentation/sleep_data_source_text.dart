import '../domain/sleep_data_source.dart';

/// The user-facing name of a data source.
String sleepDataSourceLabel(SleepDataSource source) {
  return switch (source) {
    SleepDataSource.local => 'Local',
    SleepDataSource.healthConnect => 'Google Health',
  };
}

/// The privacy line shown in Settings for the active source.
String sleepDataSourcePrivacy(SleepDataSource source) {
  return switch (source) {
    SleepDataSource.local => 'On-device only.',
    SleepDataSource.healthConnect =>
      'Stored in Health Connect. Google Health can read it.',
  };
}
