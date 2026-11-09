import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Shared entry point for the app's local notifications.
///
/// The scheduled reminder and the sleep-status notification share one plugin
/// instance, so the plugin is initialized once and every tap is routed through
/// the same callback.
class LocalNotifications {
  LocalNotifications({FlutterLocalNotificationsPlugin? plugin, this.onTap})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final VoidCallback? onTap;

  Future<void>? _initializing;

  FlutterLocalNotificationsPlugin get plugin => _plugin;

  Future<void> ensureInitialized() {
    return _initializing ??= _initialize();
  }

  /// Whether the app can currently post notifications.
  Future<bool> notificationsEnabled() async {
    await ensureInitialized();
    final android = _android;
    if (android == null) return false;
    return await android.areNotificationsEnabled() ?? false;
  }

  /// Asks Android for notification permission. Returns whether notifications
  /// are now allowed.
  Future<bool> requestPermission() async {
    await ensureInitialized();
    final android = _android;
    if (android == null) return false;
    final granted = await android.requestNotificationsPermission();
    if (granted == false) return false;
    // On Android 12 and older the request returns null because there is no
    // runtime permission. The notification block is still a valid answer.
    return await android.areNotificationsEnabled() ?? true;
  }

  /// Opens the app's notification settings in Android.
  Future<void> openNotificationSettings() async {
    await ensureInitialized();
    await _android?.openAppNotificationSettings();
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  Future<void> _initialize() async {
    try {
      final initialized = await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_notification'),
        ),
        onDidReceiveNotificationResponse: (_) => onTap?.call(),
      );
      if (initialized == false) {
        throw StateError('The notification plugin did not initialize.');
      }
    } catch (error, stackTrace) {
      _initializing = null;
      debugPrint(
        'Sleepy3: could not initialize notifications: $error\n$stackTrace',
      );
      rethrow;
    }
  }
}
