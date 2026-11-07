/// Package names the app uses in release and debug builds.
///
/// Health Connect reports the package that wrote a record. These are the two
/// packages that belong to Sleepy3; they are used to identify Sleepy3 data in
/// the UI. They do not imply that the running build can change the record:
/// Health Connect only lets the package that wrote it do that.
const sleepy3HealthSourceIds = <String>{
  'com.sleepy3.app',
  'com.sleepy3.app.debug',
};

/// Whether [sourceId] is a package written by Sleepy3.
bool isSleepy3HealthRecord(String? sourceId) =>
    sourceId != null && sleepy3HealthSourceIds.contains(sourceId);

/// Whether [sourceId] was written by the running Sleepy3 build.
///
/// This is the check for editing and deleting: a record written by the other
/// build (release or debug) is owned by another package and Health Connect
/// rejects the write.
bool isHealthRecordOwnedBy(String? sourceId, String currentPackage) =>
    sourceId != null && sourceId == currentPackage;

/// Whether [sourceId] belongs to another Sleepy3 build.
///
/// Used to explain why a Sleepy3 record is read-only instead of showing the
/// generic "another app" message.
bool isOtherSleepy3Build(String? sourceId, String currentPackage) =>
    isSleepy3HealthRecord(sourceId) && sourceId != currentPackage;
