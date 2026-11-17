import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/app_release.dart';
import '../domain/app_release_gateway.dart';

/// Reads the latest stable release from the public GitHub Releases API.
///
/// The repository is public, so no token is needed. GitHub allows 60
/// unauthenticated requests per hour and IP; Sleepy3 makes one request per app
/// launch plus the explicit checks from Settings.
class GithubAppReleaseGateway implements AppReleaseGateway {
  GithubAppReleaseGateway(
    this._client, {
    Uri? latestReleaseUri,
    this.timeout = const Duration(seconds: 10),
  }) : _latestReleaseUri = latestReleaseUri ?? defaultLatestReleaseUri;

  static final Uri defaultLatestReleaseUri = Uri.https(
    'api.github.com',
    '/repos/Juankyyy/sleepy3/releases/latest',
  );

  final http.Client _client;
  final Uri _latestReleaseUri;
  final Duration timeout;

  @override
  Future<AppRelease> fetchLatest() async {
    final response = await _client
        .get(
          _latestReleaseUri,
          headers: const {
            'Accept': 'application/vnd.github+json',
            'X-GitHub-Api-Version': '2022-11-28',
            'User-Agent': 'Sleepy3',
          },
        )
        .timeout(timeout);

    switch (response.statusCode) {
      case 200:
        break;
      case 404:
        throw const AppReleaseException(AppReleaseFailure.notFound);
      case 403:
        throw const AppReleaseException(AppReleaseFailure.rateLimited);
      default:
        throw const AppReleaseException(AppReleaseFailure.unavailable);
    }

    late final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const AppReleaseException(AppReleaseFailure.malformed);
    }

    if (decoded is! Map<String, dynamic>) {
      throw const AppReleaseException(AppReleaseFailure.malformed);
    }

    try {
      return AppRelease.fromJson(decoded);
    } on FormatException {
      throw const AppReleaseException(AppReleaseFailure.malformed);
    }
  }
}
