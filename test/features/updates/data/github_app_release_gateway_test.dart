import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sleepy3/features/updates/data/github_app_release_gateway.dart';
import 'package:sleepy3/features/updates/domain/app_release_gateway.dart';

void main() {
  final uri = Uri.parse(
    'https://github.com/Juankyyy/sleepy3/releases/tag/v0.4.0',
  );
  final body = jsonEncode({
    'tag_name': 'v0.4.0',
    'name': 'v0.4.0 - The Widget Update',
    'html_url': uri.toString(),
    'body':
        '<!-- title: v0.4.0 -->\n\nA short summary.\n\n'
        '## Highlights\n\n- First change.',
    'assets': [
      {
        'name': 'sleepy3-v0.4.0.apk',
        'browser_download_url':
            'https://github.com/Juankyyy/sleepy3/releases/download/'
            'v0.4.0/sleepy3-v0.4.0.apk',
      },
    ],
  });

  test('requests the latest release with the GitHub headers', () async {
    late http.Request captured;
    final gateway = GithubAppReleaseGateway(
      MockClient((request) async {
        captured = request;
        return http.Response(body, 200);
      }),
    );

    await gateway.fetchLatest();

    expect(captured.url, GithubAppReleaseGateway.defaultLatestReleaseUri);
    expect(captured.method, 'GET');
    expect(captured.headers['Accept'], 'application/vnd.github+json');
    expect(captured.headers['X-GitHub-Api-Version'], '2022-11-28');
    expect(captured.headers['User-Agent'], 'Sleepy3');
  });

  test('parses a release response', () async {
    final gateway = GithubAppReleaseGateway(
      MockClient((request) async => http.Response(body, 200)),
    );

    final release = await gateway.fetchLatest();

    expect(release.version, '0.4.0');
    expect(release.displayName, 'The Widget Update');
    expect(release.apkUrl, isNotNull);
    expect(release.notes, contains('A short summary.'));
    expect(release.notes, contains('## Highlights'));
  });

  test('maps GitHub statuses to failures', () async {
    Future<void> expectFailure(int status, AppReleaseFailure failure) async {
      final gateway = GithubAppReleaseGateway(
        MockClient((request) async => http.Response('{}', status)),
      );

      await expectLater(
        gateway.fetchLatest(),
        throwsA(
          isA<AppReleaseException>().having(
            (error) => error.failure,
            'failure',
            failure,
          ),
        ),
      );
    }

    await expectFailure(404, AppReleaseFailure.notFound);
    await expectFailure(403, AppReleaseFailure.rateLimited);
    await expectFailure(500, AppReleaseFailure.unavailable);
  });

  test('rejects invalid JSON and invalid release payloads', () async {
    final invalidJson = GithubAppReleaseGateway(
      MockClient((request) async => http.Response('not json', 200)),
    );
    await expectLater(
      invalidJson.fetchLatest(),
      throwsA(isA<AppReleaseException>()),
    );

    final missingTag = GithubAppReleaseGateway(
      MockClient(
        (request) async =>
            http.Response(jsonEncode({'html_url': uri.toString()}), 200),
      ),
    );
    await expectLater(
      missingTag.fetchLatest(),
      throwsA(isA<AppReleaseException>()),
    );
  });

  test('times out a slow request', () async {
    final gateway = GithubAppReleaseGateway(
      MockClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return http.Response(body, 200);
      }),
      timeout: const Duration(milliseconds: 1),
    );

    await expectLater(gateway.fetchLatest(), throwsA(isA<TimeoutException>()));
  });
}
