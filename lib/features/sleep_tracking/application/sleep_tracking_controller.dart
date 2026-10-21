import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/sleep_session.dart';

/// Injectable clock so the state machine is deterministic in tests.
typedef SleepClock = DateTime Function();

final sleepClockProvider = Provider<SleepClock>((ref) => DateTime.now);

class SleepTrackingState {
  const SleepTrackingState({this.openSession, this.lastSession});

  final SleepSession? openSession;
  final SleepSession? lastSession;

  bool get isSleeping => openSession != null;
}

/// Owns the Sleep / Wake state machine.
///
/// This is deliberately synchronous and UI-free: persistence, Health Connect
/// and the home-screen widget will subscribe to the same state later.
class SleepTrackingController extends Notifier<SleepTrackingState> {
  @override
  SleepTrackingState build() => const SleepTrackingState();

  void sleep() {
    if (state.openSession != null) return;
    final now = ref.read(sleepClockProvider)();
    state = SleepTrackingState(
      openSession: SleepSession(startedAt: now),
      lastSession: state.lastSession,
    );
  }

  void wake() {
    final open = state.openSession;
    if (open == null) return;
    final now = ref.read(sleepClockProvider)();
    state = SleepTrackingState(lastSession: open.finish(now));
  }
}

final sleepTrackingControllerProvider =
    NotifierProvider<SleepTrackingController, SleepTrackingState>(
      SleepTrackingController.new,
    );
