import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../core/theme/sleepy3_theme.dart';
import '../features/health/application/health_sync_controller.dart';
import '../features/health/application/sleep_data_source_controller.dart';
import '../features/health/domain/sleep_data_source.dart';
import '../features/settings/application/theme_mode_controller.dart';
import '../features/settings/domain/app_theme_mode.dart';
import '../features/sleep_tracking/application/sleep_tracking_controller.dart';
import 'sleepy3_shell.dart';

/// Runs the app with the Sleepy3 scheme for the selected theme mode.
///
/// Brightness is resolved here instead of through `M3EMaterialApp.autoTheming`
/// because that path derives its dark template from the light primary. Sleepy3
/// generates light and dark independently from the same seed, so the resolved
/// scheme is handed to `M3EMaterialApp` as both the expressive data and the
/// Material theme.
class Sleepy3App extends ConsumerStatefulWidget {
  const Sleepy3App({super.key});

  @override
  ConsumerState<Sleepy3App> createState() => _Sleepy3AppState();
}

class _Sleepy3AppState extends ConsumerState<Sleepy3App>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Connection permission checks must not delay the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_retryPendingUploads());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_retryPendingUploads());
    }
  }

  /// Retries failed Health Connect uploads when the app opens or comes back.
  ///
  /// Local mode never writes to Health Connect automatically.
  Future<void> _retryPendingUploads() async {
    if (!mounted) return;
    if (ref.read(sleepDataSourceProvider) != SleepDataSource.healthConnect) {
      return;
    }

    final sync = ref.read(healthSyncControllerProvider.notifier);
    final result = await sync.retryPending();
    if (!mounted) return;

    if (result.total == 0) {
      // Nothing to upload; still refresh the status because the connection
      // state can change while the app is in the background.
      await sync.refresh();
      return;
    }

    // A retry changes what Health Connect contains.
    await ref.read(sleepTrackingControllerProvider.notifier).reloadHistory();
  }

  @override
  void didChangePlatformBrightness() {
    // A pinned light/dark theme does not depend on the system brightness.
    if (ref.read(themeModeControllerProvider) != AppThemeMode.system) return;
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(themeModeControllerProvider);
    final platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final data = Sleepy3Theme.forBrightness(
      mode.resolveBrightness(platformBrightness),
    );

    return M3EMaterialApp(
      title: 'Sleepy3',
      data: data,
      theme: data.toThemeData(),
      darkTheme: data.toThemeData(),
      autoTheming: false,
      dynamicColoring: false,
      drawUnderSystemBars: true,
      locale: const Locale('en', 'US'),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('en', 'US')],
      home: const Sleepy3Shell(),
    );
  }
}
