/// Package names the app uses in release and debug builds.
///
/// Health Connect reports the package that wrote a record. Only these two
/// belong to Sleepy3, so only records with one of these source ids can be
/// edited or deleted from Google Health.
const sleepy3HealthSourceIds = <String>{
  'com.sleepy3.app',
  'com.sleepy3.app.debug',
};

/// Whether [sourceId] is a package written by Sleepy3.
bool isSleepy3HealthRecord(String? sourceId) =>
    sourceId != null && sleepy3HealthSourceIds.contains(sourceId);
