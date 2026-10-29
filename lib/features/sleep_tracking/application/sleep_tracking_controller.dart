import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../health/application/sleep_data_source_controller.dart';
import '../../health/application/sleep_history_controller.dart';
import '../../health/domain/sleep_data_source.dart';
import '../domain/sleep_session.dart';
import 'sleep_tracking_providers.dart';

export 'sleep_tracking_providers.dart';

/// Whether the closed history is available yet.
enum SleepHistoryStatus {
  /// No load has finished or even started.
  initial,

  /// The selected source is being read.
  loading,

  /// [SleepTrackingState.closedSessions] is ready, even when it is empty.
  ready,

  /// The selected source could not be read.
  error,
}

/// Owns the Sleep / Wake state machine and the closed history.
///
/// The open session always lives in Drift so it can be restored after a crash.
/// The closed list comes from the selected [SleepDataSource] and never mixes
/// both sources.
class SleepTrackingState {
  const SleepTrackingState({
    this.openSession,
    this.closedSessions = const [],
    this.historyStatus = SleepHistoryStatus.initial,
    this.historyError,
  });

  static const _unset = Object();

  final SleepSession? openSession;

  /// Every finished session from the selected source, oldest first.
  final List<SleepSession> closedSessions;

  final SleepHistoryStatus historyStatus;

  /// The exception that made [historyStatus] [SleepHistoryStatus.error].
  final Object? historyError;

  /// The most recently stored closed session, used for the session line.
  SleepSession? get lastSession =>
      closedSessions.isEmpty ? null : closedSessions.last;

  bool get isSleeping => openSession != null;

  SleepTrackingState copyWith({
    Object? openSession = _unset,
    List<SleepSession>? closedSessions,
    SleepHistoryStatus? historyStatus,
    Object? historyError = _unset,
  }) {
    return SleepTrackingState(
      openSession: identical(openSession, _unset)
          ? this.openSession
          : openSession as SleepSession?,
      closedSessions: closedSessions ?? this.closedSessions,
      historyStatus: historyStatus ?? this.historyStatus,
      historyError: identical(historyError, _unset)
          ? this.historyError
          : historyError,
    );
  }
}

/// Owns the Sleep / Wake state machine.
///
/// Taps update [state] immediately, then persist through an ordered write
/// queue. The local row is always written, even in Google Health mode, as a
/// safety copy. The visible closed history is then reloaded from the selected
/// source.
class SleepTrackingController extends Notifier<SleepTrackingState> {
  Future<void> _writeQueue = Future<void>.value();
  final SleepHistoryController _history = SleepHistoryController();
  Future<void> _historyFuture = Future<void>.value();

  @override
  SleepTrackingState build() {
    final initial = ref.watch(initialSleepSnapshotProvider);

    // The source preference can change from Settings while this controller is
    // alive. Drop the old list immediately so a Local session is never shown
    // in Health Connect mode.
    ref.listen<SleepDataSource>(sleepDataSourceProvider, (previous, next) {
      if (previous == next || !ref.mounted) return;
      _history.invalidate();
      state = state.copyWith(
        closedSessions: const [],
        historyStatus: SleepHistoryStatus.loading,
        historyError: null,
      );
      _historyFuture = Future.microtask(_loadHistory);
    });

    _historyFuture = Future.microtask(_loadHistory);

    return SleepTrackingState(
      openSession: initial.openSession,
      historyStatus: SleepHistoryStatus.initial,
    );
  }

  /// The load currently in flight, so tests and Retry can await it.
  Future<void> get historyLoad => _historyFuture;

  Future<void> sleep() async {
    if (state.openSession != null) return;

    final now = ref.read(sleepClockProvider)();
    final session = SleepSession(startedAt: now);
    state = state.copyWith(openSession: session);

    final store = ref.read(sleepSessionStoreProvider);
    await _enqueueWrite(() => store.startSession(session));
  }

  Future<void> wake() async {
    final open = state.openSession;
    if (open == null) return;

    final now = ref.read(sleepClockProvider)();
    final finished = open.finish(now);
    final source = ref.read(sleepDataSourceProvider);

    // In Local mode the finished session can join the list immediately. In
    // Google Health mode only Health Connect is shown, so the local copy must
    // stay hidden until it is confirmed there.
    state = state.copyWith(
      openSession: null,
      closedSessions: source == SleepDataSource.local
          ? [...state.closedSessions, finished]
          : state.closedSessions,
    );

    final store = ref.read(sleepSessionStoreProvider);
    await _enqueueWrite(() => store.finishOpenSession(finished.endedAt!));
    await reloadHistory();
  }

  /// Reloads the closed history from the selected source.
  ///
  /// Used by the Retry action and after Wake. The open session is untouched.
  Future<void> reloadHistory() {
    final future = _loadHistory();
    _historyFuture = future;
    return future;
  }

  Future<void> _loadHistory() async {
    if (!ref.mounted) return;

    final generation = _history.begin();
    final source = ref.read(sleepDataSourceProvider);

    state = state.copyWith(
      closedSessions: const [],
      historyStatus: SleepHistoryStatus.loading,
      historyError: null,
    );

    try {
      final repository = ref.read(sleepHistoryRepositoryProvider);
      final sessions = await repository.loadClosedSessions();
      if (!ref.mounted || !_history.isCurrent(generation)) return;
      // A source switch invalidates the load; this is belt and braces for a
      // listener that has not run yet.
      if (ref.read(sleepDataSourceProvider) != source) return;

      state = state.copyWith(
        closedSessions: List.unmodifiable(sessions),
        historyStatus: SleepHistoryStatus.ready,
        historyError: null,
      );
    } catch (error, stackTrace) {
      if (!ref.mounted || !_history.isCurrent(generation)) return;
      debugPrint('Sleepy3: could not load sleep history: $error\n$stackTrace');
      state = state.copyWith(
        closedSessions: const [],
        historyStatus: SleepHistoryStatus.error,
        historyError: error,
      );
    }
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
