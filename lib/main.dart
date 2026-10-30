import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app/sleepy3_app.dart';
import 'features/health/application/health_connect_gateway_provider.dart';
import 'features/health/application/health_sync_store_provider.dart';
import 'features/health/application/sleep_data_source_controller.dart';
import 'features/health/data/drift_health_sync_store.dart';
import 'features/health/data/health_connect_gateway_impl.dart';
import 'features/health/domain/sleep_data_source.dart';
import 'features/settings/application/app_version_provider.dart';
import 'features/settings/application/theme_mode_controller.dart';
import 'features/settings/data/drift_settings_store.dart';
import 'features/settings/domain/app_theme_mode.dart';
import 'features/settings/domain/app_version.dart';
import 'features/settings/domain/settings_store.dart';
import 'features/sleep_tracking/application/sleep_tracking_controller.dart';
import 'features/sleep_tracking/data/drift_sleep_session_store.dart';
import 'features/sleep_tracking/data/sleepy3_database.dart';
import 'features/sleep_tracking/domain/sleep_session.dart';
import 'features/sleep_tracking/domain/sleep_session_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = Sleepy3Database();
  final store = DriftSleepSessionStore(database);
  final healthSyncStore = DriftHealthSyncStore(database);
  final settingsStore = DriftSettingsStore(database);
  final healthGateway = HealthConnectGatewayImpl();
  final openSession = await _loadOpenSession(store);
  final themeMode = await _loadThemeMode(settingsStore);
  final dataSource = await _loadSleepDataSource(settingsStore);
  final appVersion = await _loadAppVersion();

  runApp(
    ProviderScope(
      overrides: [
        sleepSessionStoreProvider.overrideWithValue(store),
        initialSleepSnapshotProvider.overrideWithValue(
          SleepSnapshot(openSession: openSession),
        ),
        settingsStoreProvider.overrideWithValue(settingsStore),
        initialThemeModeProvider.overrideWithValue(themeMode),
        healthConnectGatewayProvider.overrideWithValue(healthGateway),
        healthSyncStoreProvider.overrideWithValue(healthSyncStore),
        initialSleepDataSourceProvider.overrideWithValue(dataSource),
        appVersionProvider.overrideWithValue(appVersion),
      ],
      child: const Sleepy3App(),
    ),
  );
}

Future<SleepSession?> _loadOpenSession(SleepSessionStore store) async {
  try {
    return await store.loadOpenSession();
  } catch (error, stackTrace) {
    // The app can still track in memory; a failed read must not block launch.
    debugPrint('Sleepy3: could not load the open session: $error\n$stackTrace');
    return null;
  }
}

Future<AppThemeMode> _loadThemeMode(SettingsStore store) async {
  try {
    return await store.loadThemeMode();
  } catch (error, stackTrace) {
    debugPrint('Sleepy3: could not load theme: $error\n$stackTrace');
    return AppThemeMode.system;
  }
}

Future<SleepDataSource> _loadSleepDataSource(SettingsStore store) async {
  try {
    return await store.loadSleepDataSource();
  } catch (error, stackTrace) {
    debugPrint(
      'Sleepy3: could not load the sleep data source: $error\n$stackTrace',
    );
    return SleepDataSource.local;
  }
}

Future<AppVersion?> _loadAppVersion() async {
  try {
    final info = await PackageInfo.fromPlatform();
    if (info.version.isEmpty) return null;
    return AppVersion(version: info.version, buildNumber: info.buildNumber);
  } catch (error, stackTrace) {
    // Version is informational; a missing plugin must not block launch.
    debugPrint('Sleepy3: could not load app version: $error\n$stackTrace');
    return null;
  }
}
