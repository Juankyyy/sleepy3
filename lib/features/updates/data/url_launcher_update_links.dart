import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/update_link_launcher.dart';

/// Opens update links with the platform browser or download manager.
class UrlLauncherUpdateLinks implements UpdateLinkLauncher {
  const UrlLauncherUpdateLinks();

  @override
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error, stackTrace) {
      debugPrint('Sleepy3: could not open $uri: $error\n$stackTrace');
      return false;
    }
  }
}
