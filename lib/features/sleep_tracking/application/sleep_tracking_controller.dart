import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/sleep_session.dart';
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

/// Overridden in `main` with the snapshot loaded before the first frame.
final initialSleepSnapshotProvider = Provider<SleepSnapshot>(
  (ref) => SleepSnapshot.empty,
);

class SleepTrackingState {
  const SleepTrackingState({this.openSession, this.lastSession});

  final SleepSession? openSession;
  final SleepSession? lastSession;

  bool get isSleeping => openSession != null;
}

/// Owns the Sleep / Wake state machine.
///
/// Taps update [state] immediately, then persist through an ordered write
/// queue. Health Connect and the home-screen widget will subscribe to the same
/// state later.
class SleepTrackingController extends Notifier<SleepTrackingState> {
  Future<void> _writeQueue = Future<void>.value();

  @override
  SleepTrackingState build() {
    final initial = ref.watch(initialSleepSnapshotProvider);
    return SleepTrackingState(
      openSession: initial.openSession,
      lastSession: initial.lastSession,
    );
  }

  Future<void> sleep() async {
    if (state.openSession != null) return;

    final now = ref.read(sleepClockProvider)();
    final session = SleepSession(startedAt: now);
    state = SleepTrackingState(
      openSession: session,
      lastSession: state.lastSession,
    );

    final store = ref.read(sleepSessionStoreProvider);
    await _enqueueWrite(() => store.startSession(session));
  }

  Future<void> wake() async {
    final open = state.openSession;
    if (open == null) return;

    final now = ref.read(sleepClockProvider)();
    final finished = open.finish(now);
    state = SleepTrackingState(lastSession: finished);

    final store = ref.read(sleepSessionStoreProvider);
    await _enqueueWrite(() => store.finishOpenSession(finished.endedAt!));
  }

  Future<void> _enqueueWrite(Future<void> Function() action) {
    final next = _writeQueue.then((_) => action()).catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      // A failed write must not take down the UI or block the next tap.
      // TODO: surface this in the UI once there is an error surface.
      debugPrint('Sleepy3: could not persist session: $error\n$stackTrace');
    });
    _writeQueue = next;
    return next;
  }
}

final sleepTrackingControllerProvider =
    NotifierProvider<SleepTrackingController, SleepTrackingState>(
      SleepTrackingController.new,
    );
