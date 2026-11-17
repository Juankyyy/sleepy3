import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../core/notifications/local_notifications.dart';
import '../core/notifications/notification_providers.dart';
import '../core/startup/startup_providers.dart';
import '../core/theme/sleepy3_theme.dart';
import '../features/health/application/health_history_permission_controller.dart';
import '../features/health/application/health_sync_controller.dart';
import '../features/health/application/sleep_data_source_controller.dart';
import '../features/health/domain/sleep_data_source.dart';
import '../features/reminders/application/sleep_reminder_controller.dart';
import '../features/settings/application/language_controller.dart';
import '../features/settings/application/sleep_goal_controller.dart';
import '../features/settings/application/theme_mode_controller.dart';
import '../features/settings/application/time_format_controller.dart';
import '../features/settings/domain/app_theme_mode.dart';
import '../l10n/l10n.dart';
import '../features/sleep_tracking/application/sleep_tracking_controller.dart';
import '../features/sleep_tracking/application/sleeping_notification_controller.dart';
import '../features/updates/application/app_update_controller.dart';
import 'sleepy3_shell.dart';
import 'splash_gate.dart';

/// Runs the app with the Sleepy3 scheme for the selected theme mode.
///
/// Brightness is resolved here instead of through `M3EMaterialApp.autoTheming`
/// because Sleepy3 has two fixed brand schemes. The light and dark palettes use
/// different exact backgrounds and accents, so the resolved scheme is handed to
/// `M3EMaterialApp` as both the expressive data and the Material theme.
class Sleepy3App extends ConsumerStatefulWidget {
  const Sleepy3App({super.key, this.splashStartSignal});

  /// Completes when the splash intro may start. Tests pass a completed future
  /// because they do not rasterize frames; production uses the engine signal.
  final Future<void>? splashStartSignal;

  @override
  ConsumerState<Sleepy3App> createState() => _Sleepy3AppState();
}

class _Sleepy3AppState extends ConsumerState<Sleepy3App>
    with WidgetsBindingObserver {
  StreamSubscription<NotificationResponse>? _notificationResponses;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notificationResponses = ref
        .read(localNotificationsProvider)
        .responses
        .listen((response) => unawaited(_handleNotificationResponse(response)));
    // Initialize eagerly so a cold-start action is delivered even when the
    // reminder and the sleep card are both turned off.
    unawaited(_initializeNotifications());
    unawaited(_syncSleepReminder());
    unawaited(_syncSleepingNotification());
  }

  Future<void> _initializeNotifications() async {
    try {
      await ref.read(localNotificationsProvider).ensureInitialized();
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not initialize notifications: $error\n$stackTrace',
      );
    }
  }

  /// Applies a tap or action from the shared notification plugin.
  ///
  /// Every response selects Home, as before. The reminder's Start sleep action
  /// then follows the normal Sleep path, including the open session, the
  /// ongoing card and the reminder pause.
  Future<void> _handleNotificationResponse(
    NotificationResponse response,
  ) async {
    if (!mounted) return;
    ref.read(notificationHomeRequestProvider.notifier).requestHome();
    if (response.actionId != startSleepNotificationActionId) return;
    if (!mounted) return;

    final state = ref.read(sleepTrackingControllerProvider);
    if (state.isSleeping) return;
    await ref.read(sleepTrackingControllerProvider.notifier).sleep();
    if (!mounted) return;
    // The action can arrive before the first build installs the state
    // listeners, so update both notifications explicitly as well.
    await _syncSleepReminder(isSleeping: true);
    await _syncSleepingNotification(allowPermissionPrompt: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_retryPendingUploads());
      unawaited(_syncSleepReminder());
      unawaited(_syncSleepingNotification());
    }
  }

  /// Keeps the scheduled reminder aligned with the current state.
  ///
  /// A sleeping session pauses it; app start, resume and a language change
  /// re-arm it with the current copy.
  Future<void> _syncSleepReminder({bool? isSleeping}) async {
    if (!mounted) return;
    final sleeping =
        isSleeping ?? ref.read(sleepTrackingControllerProvider).isSleeping;
    await ref
        .read(sleepReminderControllerProvider.notifier)
        .sync(isSleeping: sleeping);
  }

  /// Keeps the ongoing sleep notification in sync with the open session.
  ///
  /// The permission dialog is only allowed when the user starts a sleep,
  /// never on launch or resume.
  Future<void> _syncSleepingNotification({
    bool allowPermissionPrompt = false,
  }) async {
    if (!mounted) return;
    final openSession = ref.read(sleepTrackingControllerProvider).openSession;
    await ref
        .read(sleepingNotificationControllerProvider)
        .sync(
          openSession: openSession,
          allowPermissionPrompt: allowPermissionPrompt,
        );
  }

  /// Retries failed Health Connect uploads when the app opens or comes back.
  ///
  /// Local mode only retries updates of sessions that already exist in Health
  /// Connect; it never uploads a new local session automatically. Google
  /// Health mode also re-reads the history permission, because the user can
  /// change it in Health Connect settings while the app is in the background.
  /// Starts the once-per-launch GitHub release check after the splash.
  Future<void> _checkForUpdates() async {
    if (!mounted) return;
    await ref.read(appUpdateControllerProvider.notifier).checkOnLaunch();
  }

  Future<void> _retryPendingUploads() async {
    if (!mounted) return;

    final sync = ref.read(healthSyncControllerProvider.notifier);
    if (ref.read(sleepDataSourceProvider) == SleepDataSource.local) {
      await sync.retryPending();
      return;
    }

    final history = ref.read(healthHistoryPermissionProvider.notifier);
    final previousHistoryAccess = ref.read(healthHistoryPermissionProvider);
    await history.refresh();
    if (!mounted) return;
    final historyAccessChanged =
        ref.read(healthHistoryPermissionProvider) != previousHistoryAccess;

    final result = await sync.retryPending();
    if (!mounted) return;

    if (result.total == 0) {
      // Nothing to upload; still refresh the status because the connection
      // state can change while the app is in the background.
      await sync.refresh();
      if (historyAccessChanged) {
        await ref
            .read(sleepTrackingControllerProvider.notifier)
            .reloadHistory();
      }
      return;
    }

    // A retry changes what Health Connect contains.
    await ref.read(sleepTrackingControllerProvider.notifier).reloadHistory();
  }

  @override
  void didChangePlatformBrightness() {
    // The native sleep card follows the system theme even when the app theme
    // is pinned, so refresh its colors and accent on a theme change.
    unawaited(_syncSleepingNotification());
    // A pinned light/dark app theme does not depend on the system brightness.
    if (ref.read(themeModeControllerProvider) != AppThemeMode.system) return;
    setState(() {});
  }

  @override
  void dispose() {
    unawaited(_notificationResponses?.cancel());
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(themeModeControllerProvider);
    final timeFormat = ref.watch(timeFormatControllerProvider);
    final language = ref.watch(languageControllerProvider);
    final platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final data = Sleepy3Theme.forBrightness(
      mode.resolveBrightness(platformBrightness),
    );

    // A sleep session pauses the reminder; waking or changing the language
    // re-arms it from the root so the feature stays independent from the
    // Sleep/Wake controller.
    ref.listen(sleepTrackingControllerProvider.select((s) => s.isSleeping), (
      previous,
      isSleeping,
    ) {
      if (previous == isSleeping) return;
      unawaited(_syncSleepReminder(isSleeping: isSleeping));
    });

    // A new open session updates the sleep notification; the transition from
    // awake to sleeping is the only path allowed to ask for permission.
    ref.listen(sleepTrackingControllerProvider.select((s) => s.openSession), (
      previous,
      next,
    ) {
      if (previous == next) return;
      unawaited(
        _syncSleepingNotification(
          allowPermissionPrompt: previous == null && next != null,
        ),
      );
    });
    ref.listen(languageControllerProvider, (previous, next) {
      if (previous == next) return;
      unawaited(_syncSleepReminder());
      unawaited(_syncSleepingNotification());
    });
    ref.listen(timeFormatControllerProvider, (previous, next) {
      if (previous == next) return;
      unawaited(_syncSleepingNotification());
    });
    // The open notification repeats the goal and its end time.
    ref.listen(sleepGoalProvider, (previous, next) {
      if (previous == next) return;
      unawaited(_syncSleepingNotification());
    });

    // Every time in the app already reads MediaQuery.alwaysUse24HourFormat,
    // including M3ETimePicker. Overriding it here keeps the clock, the history
    // times and the pickers on the same 12/24-hour choice.
    return MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(alwaysUse24HourFormat: timeFormat.uses24HourFormat),
      child: M3EMaterialApp(
        title: 'Sleepy3',
        data: data,
        theme: data.toThemeData(),
        darkTheme: data.toThemeData(),
        autoTheming: false,
        dynamicColoring: false,
        drawUnderSystemBars: true,
        locale: language.locale,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SplashGate(
          startSignal: widget.splashStartSignal,
          onFinished: () {
            if (!mounted) return;
            ref.read(splashCompletedProvider.notifier).complete();
            unawaited(_retryPendingUploads());
            unawaited(_checkForUpdates());
          },
          child: const Sleepy3Shell(),
        ),
      ),
    );
  }
}
