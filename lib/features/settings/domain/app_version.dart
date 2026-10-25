/// The installed app version, shown in Settings > About.
class AppVersion {
  const AppVersion({required this.version, this.buildNumber});

  final String version;
  final String? buildNumber;

  /// `0.1.0 (1)` when a build number is available, `0.1.0` otherwise.
  String get display {
    final build = buildNumber;
    if (build == null || build.isEmpty) return version;
    return '$version ($build)';
  }
}
