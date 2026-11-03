import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/app_info_gateway.dart';

/// [AppInfoGateway] backed by the small Android `AppInfoBridge`.
///
/// Labels do not change while the app is running, so successful lookups are
/// cached. A missing plugin or an uninstalled package returns null and the
/// caller falls back to a generic label.
class MethodChannelAppInfoGateway implements AppInfoGateway {
  MethodChannelAppInfoGateway({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  /// Method channel shared with `AppInfoBridge.kt`.
  static const channelName = 'com.sleepy3.app/app_info';

  final MethodChannel _channel;
  final Map<String, String> _labels = {};

  @override
  Future<String?> appLabelForPackage(String packageName) async {
    final package = packageName.trim();
    if (package.isEmpty) return null;

    final cached = _labels[package];
    if (cached != null) return cached;

    try {
      final label = await _channel.invokeMethod<String>('appLabelForPackage', {
        'packageName': package,
      });
      final normalized = label?.trim();
      if (normalized == null || normalized.isEmpty) return null;
      _labels[package] = normalized;
      return normalized;
    } on PlatformException catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not read the label of $package: $error\n$stackTrace',
      );
      return null;
    } on MissingPluginException catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: app info bridge is unavailable: $error\n$stackTrace',
      );
      return null;
    }
  }
}
