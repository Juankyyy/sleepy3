import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/updates/domain/app_release.dart';

void main() {
  Map<String, dynamic> json({
    String tag = 'v0.4.0',
    String name = 'v0.4.0 - The Widget Update',
    String page = 'https://github.com/Juankyyy/sleepy3/releases/tag/v0.4.0',
    String? body = '<!-- title: v0.4.0 -->\n\nA short summary.',
    List<Map<String, String>>? assets,
  }) {
    return {
      'tag_name': tag,
      'name': name,
      'html_url': page,
      'body': body,
      'assets':
          assets ??
          [
            {
              'name': 'sleepy3-v0.4.0.apk',
              'browser_download_url':
                  'https://github.com/Juankyyy/sleepy3/releases/download/'
                  'v0.4.0/sleepy3-v0.4.0.apk',
            },
            {
              'name': 'sleepy3-v0.4.0.apk.sha256',
              'browser_download_url':
                  'https://github.com/Juankyyy/sleepy3/releases/download/'
                  'v0.4.0/sleepy3-v0.4.0.apk.sha256',
            },
          ],
    };
  }

  test('reads the tag, page, APK and summary', () {
    final release = AppRelease.fromJson(json());

    expect(release.tag, 'v0.4.0');
    expect(release.version, '0.4.0');
    expect(release.displayName, 'The Widget Update');
    expect(
      release.pageUrl,
      Uri.parse('https://github.com/Juankyyy/sleepy3/releases/tag/v0.4.0'),
    );
    expect(
      release.apkUrl,
      Uri.parse(
        'https://github.com/Juankyyy/sleepy3/releases/download/v0.4.0/'
        'sleepy3-v0.4.0.apk',
      ),
    );
    expect(release.summary, 'A short summary.');
  });

  test('accepts a release without an APK asset', () {
    final release = AppRelease.fromJson(json(assets: const []));

    expect(release.apkUrl, isNull);
  });

  test('accepts an uppercase APK asset', () {
    final release = AppRelease.fromJson(
      json(
        assets: const [
          {
            'name': 'SLEEPY3-V0.4.0.APK',
            'browser_download_url':
                'https://github.com/Juankyyy/sleepy3/releases/download/'
                'v0.4.0/sleepy3-v0.4.0.apk',
          },
        ],
      ),
    );

    expect(release.apkUrl, isNotNull);
  });

  test('falls back to the app and version without a theme name', () {
    final release = AppRelease.fromJson(json(name: 'v0.4.0'));

    expect(release.displayName, 'Sleepy3 0.4.0');
  });

  test('rejects missing or invalid fields', () {
    expect(
      () => AppRelease.fromJson(json(tag: 'latest')),
      throwsFormatException,
    );
    expect(
      () => AppRelease.fromJson(json(page: 'not a url')),
      throwsFormatException,
    );
    expect(
      () => AppRelease.fromJson(json(page: 'http://example.com/release')),
      throwsFormatException,
    );
  });

  test('ignores a non-https APK URL', () {
    final release = AppRelease.fromJson(
      json(
        assets: const [
          {
            'name': 'sleepy3-v0.4.0.apk',
            'browser_download_url': 'http://example.com/sleepy3.apk',
          },
        ],
      ),
    );

    expect(release.apkUrl, isNull);
  });
}
