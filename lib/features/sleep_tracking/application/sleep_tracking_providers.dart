import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/sleep_session_store.dart';

/// Injectable clock so the state machine is deterministic in tests.
typedef SleepClock = DateTime Function();

final sleepClockProvider = Provider<SleepClock>((ref) => DateTime.now);

/// Overridden in `main` with the Drift-backed store.
final sleepSessionStoreProvider = Provider<SleepSessionStore>((ref) {
  throw UnimplementedError(
    'sleepSessionStoreProvider must be overridden with a SleepSessionStore',
  );
});

/// Overridden in `main` with the open session loaded before the first frame.
///
/// The closed history is not loaded here: Home and Stats load it
/// asynchronously from the selected [SleepDataSource].
final initialSleepSnapshotProvider = Provider<SleepSnapshot>(
  (ref) => SleepSnapshot.empty,
);
