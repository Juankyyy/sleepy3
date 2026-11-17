/// A comparable `major.minor.patch` version.
///
/// It parses the leading numeric part of a version string so build suffixes
/// and metadata (`-debug`, `+30`, `-beta.1`) do not affect the comparison.
/// GitHub tags and `package_info_plus` versions both fit this shape.
class AppVersionNumber implements Comparable<AppVersionNumber> {
  const AppVersionNumber(this.major, this.minor, this.patch);

  final int major;
  final int minor;
  final int patch;

  static final RegExp _pattern = RegExp(r'^[vV]?\s*(\d+)\.(\d+)\.(\d+)');

  /// Parses [value], or returns null when it has no `major.minor.patch` core.
  static AppVersionNumber? tryParse(String value) {
    final match = _pattern.firstMatch(value.trim());
    if (match == null) return null;

    final major = int.tryParse(match.group(1)!);
    final minor = int.tryParse(match.group(2)!);
    final patch = int.tryParse(match.group(3)!);
    if (major == null || minor == null || patch == null) return null;

    return AppVersionNumber(major, minor, patch);
  }

  bool isNewerThan(AppVersionNumber other) => compareTo(other) > 0;

  @override
  int compareTo(AppVersionNumber other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  @override
  bool operator ==(Object other) {
    return other is AppVersionNumber &&
        other.major == major &&
        other.minor == minor &&
        other.patch == patch;
  }

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
}
