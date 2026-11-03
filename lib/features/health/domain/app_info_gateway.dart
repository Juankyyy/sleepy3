/// Platform boundary for the labels of installed apps.
///
/// Health Connect reports the package that wrote a record, but the session
/// editor needs a human-readable name. The Android `PackageManager` is the only
/// source for that label, so it stays behind this small gateway.
abstract interface class AppInfoGateway {
  /// The Android label of [packageName], or null when the app is not installed
  /// or the platform cannot answer.
  Future<String?> appLabelForPackage(String packageName);
}
