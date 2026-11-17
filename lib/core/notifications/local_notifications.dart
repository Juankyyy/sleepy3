import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Reads the launch details the plugin keeps for a cold start.
///
/// Injectable so tests can exercise the launch path without the platform
/// channel. Production uses [FlutterLocalNotificationsPlugin] directly.
typedef NotificationLaunchDetailsReader =
    Future<NotificationAppLaunchDetails?> Function();

/// Initializes the plugin and registers the response callback.
///
/// Injectable so tests can drive [LocalNotifications.responses] without the
/// platform channel. Production uses [FlutterLocalNotificationsPlugin].
typedef NotificationInitializer = Future<bool?> Function({
  required InitializationSettings settings,
  DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
});

/// Action on the nightly reminder that starts a sleep session.
///
/// The app receives it through [LocalNotifications.responses] and applies the
/// normal Sleep path, so the reminder never writes a session on its own.
const String startSleepNotificationActionId = 'start-sleep';

/// Shared entry point for the app's local notifications.
///
/// The scheduled reminder and the sleep-status notification share one plugin
/// instance, so the plugin is initialized once and every tap or action is
/// delivered through [responses]. The app decides what each one does.
class LocalNotifications {
  LocalNotifications({
    FlutterLocalNotificationsPlugin? plugin,
    NotificationLaunchDetailsReader? readLaunchDetails,
    NotificationInitializer? initialize,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin() {
    _readLaunchDetails =
        readLaunchDetails ?? _plugin.getNotificationAppLaunchDetails;
    _initializePlugin = initialize ?? _initializeWithPlugin;
  }

  final FlutterLocalNotificationsPlugin _plugin;
  final _responses = StreamController<NotificationResponse>.broadcast();
  late final NotificationLaunchDetailsReader _readLaunchDetails;
  late final NotificationInitializer _initializePlugin;

  Future<void>? _initializing;

  FlutterLocalNotificationsPlugin get plugin => _plugin;

  /// Taps and action taps from the plugin, including a cold-start action.
  Stream<NotificationResponse> get responses => _responses.stream;

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
      final initialized = await _initializePlugin(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_notification'),
        ),
        onDidReceiveNotificationResponse: _deliver,
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

    // A foreground notification action launches the app without going through
    // the callback above. The plugin keeps that response in the activity's
    // launch intent, so the cold-start action is read once here.
    NotificationAppLaunchDetails? launchDetails;
    try {
      launchDetails = await _readLaunchDetails();
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not read the notification launch details: '
        '$error\n$stackTrace',
      );
    }
    if (launchDetails?.didNotificationLaunchApp != true) return;
    final response = launchDetails?.notificationResponse;
    if (response != null) _deliver(response);
  }

  void _deliver(NotificationResponse response) {
    if (_responses.isClosed) return;
    _responses.add(response);
  }

  Future<bool?> _initializeWithPlugin({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
  }) {
    return _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
  }
}
