import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/app_night_mode.dart';
import '../domain/app_theme_mode.dart';

/// Android implementation backed by `UiModeManager.setApplicationNightMode`.
///
/// The value is persisted by the system, so the next cold start resolves the
/// launch theme with the same night mode as the app. Failures are logged and
/// ignored: the Flutter theme does not depend on this call.
class AndroidAppNightMode implements AppNightMode {
  const AndroidAppNightMode();

  static const _channel = MethodChannel('com.sleepy3.app/app_night_mode');

  @override
  Future<void> setMode(AppThemeMode mode) async {
    try {
      await _channel.invokeMethod<void>('setApplicationNightMode', {
        'mode': mode.name,
      });
    } on MissingPluginException {
      // Widget tests and non-Android platforms do not register the channel.
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not set the app night mode: $error\n$stackTrace',
      );
    }
  }
}
