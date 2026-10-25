import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/sleepy3_app.dart';
import 'features/sleep_tracking/application/sleep_tracking_controller.dart';
import 'features/sleep_tracking/data/drift_sleep_session_store.dart';
import 'features/sleep_tracking/data/sleepy3_database.dart';
import 'features/sleep_tracking/domain/sleep_session_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = Sleepy3Database();
  final store = DriftSleepSessionStore(database);
  final initial = await _loadInitialSnapshot(store);

  runApp(
    ProviderScope(
      overrides: [
        sleepSessionStoreProvider.overrideWithValue(store),
        initialSleepSnapshotProvider.overrideWithValue(initial),
      ],
      child: const Sleepy3App(),
    ),
  );
}

Future<SleepSnapshot> _loadInitialSnapshot(SleepSessionStore store) async {
  try {
    return await store.load(now: DateTime.now());
  } catch (error, stackTrace) {
    // The app can still track in memory; a failed read must not block launch.
    debugPrint('Sleepy3: could not load sessions: $error\n$stackTrace');
    return SleepSnapshot.empty;
  }
}
