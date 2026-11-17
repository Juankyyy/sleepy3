import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../data/github_app_release_gateway.dart';
import '../data/url_launcher_update_links.dart';
import '../domain/app_release_gateway.dart';
import '../domain/update_link_launcher.dart';
import '../domain/update_prompt_preferences.dart';

/// Overridden in `main` with the preferences loaded before the first frame.
final initialUpdatePromptPreferencesProvider =
    Provider<UpdatePromptPreferences>(
      (ref) => UpdatePromptPreferences.defaults,
    );

/// The GitHub Releases client. The provider owns and closes the HTTP client.
final appReleaseGatewayProvider = Provider<AppReleaseGateway>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return GithubAppReleaseGateway(client);
});

/// Opens the release page and the APK download.
final updateLinkLauncherProvider = Provider<UpdateLinkLauncher>((ref) {
  return const UrlLauncherUpdateLinks();
});
