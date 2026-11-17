import 'app_release.dart';

/// Fetches the latest stable release.
abstract interface class AppReleaseGateway {
  Future<AppRelease> fetchLatest();
}

/// Why a release could not be read.
enum AppReleaseFailure {
  /// GitHub has no published stable release, or the repository is unavailable.
  notFound,

  /// The unauthenticated GitHub API rate limit was exhausted.
  rateLimited,

  /// The request failed or GitHub returned an unexpected status.
  unavailable,

  /// The response was not a valid release payload.
  malformed,
}

class AppReleaseException implements Exception {
  const AppReleaseException(this.failure);

  final AppReleaseFailure failure;

  @override
  String toString() => 'AppReleaseException($failure)';
}
