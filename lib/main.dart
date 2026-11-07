import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app/sleepy3_app.dart';
import 'features/health/application/current_app_package_provider.dart';
import 'features/health/application/health_connect_gateway_provider.dart';
import 'features/health/application/health_sync_store_provider.dart';
import 'features/health/application/sleep_data_source_controller.dart';
import 'features/health/data/drift_health_sync_store.dart';
import 'features/health/data/health_connect_gateway_impl.dart';
import 'features/health/domain/sleep_data_source.dart';
import 'features/settings/application/app_version_provider.dart';
import 'features/settings/application/theme_mode_controller.dart';
import 'features/settings/data/android_app_night_mode.dart';
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
  await _purgeUnrecordableSessions(store);
  final openSession = await _loadOpenSession(store);
  final themeMode = await _loadThemeMode(settingsStore);
  await const AndroidAppNightMode().setMode(themeMode);
  final dataSource = await _loadSleepDataSource(settingsStore);
  final packageInfo = await _loadPackageInfo();
  final appVersion = _appVersionFrom(packageInfo);

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
        currentAppPackageProvider.overrideWithValue(
          packageInfo?.packageName ?? 'com.sleepy3.app',
        ),
      ],
      child: const Sleepy3App(),
    ),
  );
}

/// Removes local closed sessions outside the recordable range that were never
/// published to Health Connect. They are rows written by versions that did not
/// enforce the limits yet.
Future<void> _purgeUnrecordableSessions(DriftSleepSessionStore store) async {
  try {
    final purged = await store.purgeUnrecordableSessions(
      minimumRecordableSleep,
      maximumRecordableSleep,
    );
    if (purged > 0) {
      debugPrint(
        'Sleepy3: purged $purged session(s) outside the recordable range',
      );
    }
  } catch (error, stackTrace) {
    // Leftover rows only stay in the history; purge again next launch.
    debugPrint(
      'Sleepy3: could not purge unrecordable sessions: $error\n$stackTrace',
    );
  }
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

Future<PackageInfo?> _loadPackageInfo() async {
  try {
    return await PackageInfo.fromPlatform();
  } catch (error, stackTrace) {
    // Version and package name are informational; a missing plugin must not
    // block launch. The package name also decides which Health Connect records
    // are writable, so the provider falls back to the release id.
    debugPrint('Sleepy3: could not load package info: $error\n$stackTrace');
    return null;
  }
}

AppVersion? _appVersionFrom(PackageInfo? info) {
  if (info == null || info.version.isEmpty) return null;
  return AppVersion(version: info.version, buildNumber: info.buildNumber);
}
