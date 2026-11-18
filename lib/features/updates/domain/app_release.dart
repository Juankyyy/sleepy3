import 'app_version_number.dart';
import 'release_notes.dart';

/// The latest stable release published on GitHub.
class AppRelease {
  const AppRelease({
    required this.tag,
    required this.version,
    required this.name,
    required this.pageUrl,
    required this.apkUrl,
    required this.notes,
  });

  /// The Git tag, for example `v0.4.0`.
  final String tag;

  /// The normalized semantic version, for example `0.4.0`.
  final String version;

  /// The release title, for example `v0.4.0 - The Widget Update`.
  final String name;

  /// The GitHub release page.
  final Uri pageUrl;

  /// The APK asset, when the release includes one.
  final Uri? apkUrl;

  /// The full release notes Markdown, without the metadata comments.
  final String? notes;

  /// The curated release theme (`The Widget Update`), or the app and version
  /// when the release has no separate name.
  String get displayName {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == tag) return 'Sleepy3 $version';

    final prefix = '$tag - ';
    if (trimmed.startsWith(prefix)) {
      final rest = trimmed.substring(prefix.length).trim();
      if (rest.isNotEmpty) return rest;
    }
    return trimmed;
  }

  factory AppRelease.fromJson(Map<String, dynamic> json) {
    final tag = json['tag_name'];
    if (tag is! String || tag.trim().isEmpty) {
      throw const FormatException('Missing release tag');
    }
    final number = AppVersionNumber.tryParse(tag);
    if (number == null) {
      throw FormatException('Invalid release tag: $tag');
    }

    final page = json['html_url'];
    if (page is! String) {
      throw const FormatException('Missing release page URL');
    }
    final pageUrl = Uri.tryParse(page);
    if (pageUrl == null || pageUrl.scheme != 'https' || pageUrl.host.isEmpty) {
      throw const FormatException('Invalid release page URL');
    }

    final name = json['name'];
    final body = json['body'];
    final assets = json['assets'];
    Uri? apkUrl;
    if (assets is List) {
      for (final asset in assets) {
        if (asset is! Map) continue;
        final assetName = asset['name'];
        final download = asset['browser_download_url'];
        if (assetName is! String ||
            !assetName.toLowerCase().endsWith('.apk') ||
            download is! String) {
          continue;
        }
        final uri = Uri.tryParse(download);
        if (uri != null && uri.scheme == 'https' && uri.host.isNotEmpty) {
          apkUrl = uri;
          break;
        }
      }
    }

    return AppRelease(
      tag: tag.trim(),
      version: number.toString(),
      name: name is String && name.trim().isNotEmpty ? name : tag.trim(),
      pageUrl: pageUrl,
      apkUrl: apkUrl,
      notes: normalizeReleaseNotes(body is String ? body : null),
    );
  }
}
