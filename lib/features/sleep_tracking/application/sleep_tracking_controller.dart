import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../health/application/health_history_permission_controller.dart';
import '../../health/application/health_sync_controller.dart';
import '../../health/application/sleep_data_source_controller.dart';
import '../../health/application/sleep_history_controller.dart';
import '../../health/domain/sleep_data_source.dart';
import '../domain/session_edit.dart';
import '../domain/sleep_session.dart';
import 'sleep_session_edit_service.dart';
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

/// What happened after a Wake tap.
enum SleepWakeOutcome {
  /// The session was closed and joined the visible history, after the Health
  /// Connect write when running in Google Health mode.
  closed,

  /// The sleep was shorter than [minimumRecordableSleep], so nothing was
  /// recorded. The sleep tracking screen confirms it with a dialog first;
  /// this outcome only happens when Wake reaches the controller through
  /// another path, such as a widget tap.
  discarded,
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
      _historyFuture = Future<void>.microtask(() async {
        await _loadHistory();
      });
    });

    _historyFuture = Future<void>.microtask(() async {
      await _loadHistory();
    });

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

  Future<SleepWakeOutcome> wake() async {
    final open = state.openSession;
    if (open == null) return SleepWakeOutcome.closed;

    final now = ref.read(sleepClockProvider)();
    final finished = open.finish(now);

    // A sleep outside the recordable range is never recorded, in any data
    // source mode. The sleep tracking screen asks for confirmation first (and
    // offers to fix the start of a long sleep); this also discards wake paths
    // that never had a dialog, such as a widget tap.
    if (finished.duration < minimumRecordableSleep ||
        finished.duration >= maximumRecordableSleep) {
      state = state.copyWith(openSession: null);

      final store = ref.read(sleepSessionStoreProvider);
      await _enqueueWrite(() => store.discardOpenSession());
      return SleepWakeOutcome.discarded;
    }

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

    // In Google Health mode the finished session must reach Health Connect
    // before the visible history is read again. A failure leaves the local
    // row pending; Home and Stats show the sync banner and never mix it into
    // the Health Connect list until a retry confirms it.
    if (source == SleepDataSource.healthConnect) {
      await ref
          .read(healthSyncControllerProvider.notifier)
          .uploadFinishedSession(finished);
    }

    await reloadHistory();
    return SleepWakeOutcome.closed;
  }

  /// Moves the start of the open session without closing it.
  ///
  /// Used when Wake finds a sleep of [maximumRecordableSleep] or more: the
  /// user can fix the start so the session fits the range Health Connect
  /// accepts, and the next Wake records it normally. The new start is checked
  /// with the same rules the editor uses, evaluated against the session Wake
  /// would close right now.
  ///
  /// Returns the first validation error, or null when the start was saved.
  Future<SessionEditError?> updateOpenSessionStart(DateTime startedAt) async {
    final open = state.openSession;
    if (open == null) return null;

    final now = ref.read(sleepClockProvider)();
    if (startedAt.isAfter(now)) return SessionEditError.startInTheFuture;

    final errors = validateSessionEdit(
      draft: SessionEditDraft(
        startedAt: startedAt,
        endedAt: now,
        originalStartedAt: open.startedAt,
      ),
      now: now,
      otherClosedSessions: state.closedSessions,
      // The open session is the draft itself, so it is not passed as an open
      // session to overlap against.
    );
    if (errors.isNotEmpty) return errors.first;

    state = state.copyWith(openSession: open.retimeStart(startedAt));

    final store = ref.read(sleepSessionStoreProvider);
    await _enqueueWrite(() => store.updateOpenSessionStart(startedAt));
    return null;
  }

  /// Saves new times for a finished session without reloading the history.
  ///
  /// The edit service decides whether Health Connect goes first or the local
  /// row does, and whether the change stays pending. Only a successful local
  /// change updates [SleepTrackingState.closedSessions].
  Future<SleepSessionEditResult> updateClosedSession({
    required SleepSession session,
    required DateTime startedAt,
    required DateTime endedAt,
  }) async {
    final source = ref.read(sleepDataSourceProvider);
    final otherClosedSessions = state.closedSessions
        .where((current) => !current.hasSameIdentityAs(session))
        .toList(growable: false);
    final openSession = state.openSession;

    final result = await _enqueueAction(
      () => ref
          .read(sleepSessionEditServiceProvider)
          .updateSession(
            session: session,
            startedAt: startedAt,
            endedAt: endedAt,
            source: source,
            otherClosedSessions: otherClosedSessions,
            openSession: openSession,
          ),
    );
    if (!ref.mounted) return result;

    // A source switch rebuilds the list; never apply an old-source edit to it.
    if (ref.read(sleepDataSourceProvider) == source) {
      final updated = result.session;
      if (updated != null) {
        state = state.copyWith(closedSessions: _replaceClosedSession(updated));
      }
    }
    await _refreshHealthPendingCount();
    return result;
  }

  /// Deletes a finished session without reloading the history.
  Future<SleepSessionEditResult> deleteClosedSession(
    SleepSession session,
  ) async {
    final source = ref.read(sleepDataSourceProvider);

    final result = await _enqueueAction(
      () => ref
          .read(sleepSessionEditServiceProvider)
          .deleteSession(session: session, source: source),
    );
    if (!ref.mounted) return result;

    if (result.isDeleted && ref.read(sleepDataSourceProvider) == source) {
      state = state.copyWith(
        closedSessions: List.unmodifiable(
          state.closedSessions.where(
            (current) => !current.hasSameIdentityAs(session),
          ),
        ),
      );
    }
    await _refreshHealthPendingCount();
    return result;
  }

  /// Reloads the closed history from the selected source.
  ///
  /// Used by the Retry action and after Wake. The open session is untouched.
  /// The list is cleared and shows the loading state until the read finishes;
  /// use [refreshHistory] for a manual refresh that keeps the rows visible.
  Future<void> reloadHistory() async {
    await _startHistoryLoad();
  }

  /// Re-reads the closed history without dropping the rows already on screen.
  ///
  /// Used by the Stats pull-to-refresh. Returns false only when the selected
  /// source failed and the visible history was kept. A load superseded by a
  /// source switch returns true because the new source's load owns the screen.
  Future<bool> refreshHistory() => _startHistoryLoad(keepVisible: true);

  Future<bool> _startHistoryLoad({bool keepVisible = false}) {
    final future = _loadHistory(keepVisible: keepVisible);
    _historyFuture = future.then<void>((_) {});
    return future;
  }

  Future<bool> _loadHistory({bool keepVisible = false}) async {
    if (!ref.mounted) return false;

    final generation = _history.begin();
    final source = ref.read(sleepDataSourceProvider);
    final preserveRows =
        keepVisible && state.historyStatus == SleepHistoryStatus.ready;

    if (!preserveRows) {
      state = state.copyWith(
        closedSessions: const [],
        historyStatus: SleepHistoryStatus.loading,
        historyError: null,
      );
    }

    try {
      // Resolve the history grant before choosing the read window. This also
      // happens on the first load, so a grant made in Health Connect settings
      // is honoured without opening Stats first.
      if (source == SleepDataSource.healthConnect) {
        await ref.read(healthHistoryPermissionProvider.notifier).refresh();
        if (!ref.mounted || !_history.isCurrent(generation)) return true;
        if (ref.read(sleepDataSourceProvider) != source) return true;
      }

      final repository = ref.read(sleepHistoryRepositoryProvider);
      final sessions = await repository.loadClosedSessions();
      if (!ref.mounted || !_history.isCurrent(generation)) return true;
      // A source switch invalidates the load; this is belt and braces for a
      // listener that has not run yet.
      if (ref.read(sleepDataSourceProvider) != source) return true;

      state = state.copyWith(
        closedSessions: List.unmodifiable(sessions),
        historyStatus: SleepHistoryStatus.ready,
        historyError: null,
      );
      return true;
    } catch (error, stackTrace) {
      if (!ref.mounted || !_history.isCurrent(generation)) return true;
      if (ref.read(sleepDataSourceProvider) != source) return true;

      debugPrint('Sleepy3: could not load sleep history: $error\n$stackTrace');
      if (preserveRows) {
        // The pull-to-refresh keeps the visible history and reports the
        // failure through its own surface.
        return false;
      }
      state = state.copyWith(
        closedSessions: const [],
        historyStatus: SleepHistoryStatus.error,
        historyError: error,
      );
      return false;
    }
  }

  List<SleepSession> _replaceClosedSession(SleepSession updated) {
    final sessions = <SleepSession>[];
    var replaced = false;

    for (final current in state.closedSessions) {
      if (!replaced && current.hasSameIdentityAs(updated)) {
        sessions.add(updated);
        replaced = true;
      } else {
        sessions.add(current);
      }
    }
    if (!replaced) sessions.add(updated);

    sessions.sort((a, b) => a.startedAt.compareTo(b.startedAt));
    return List.unmodifiable(sessions);
  }

  Future<void> _refreshHealthPendingCount() async {
    if (!ref.mounted) return;
    await ref.read(healthSyncControllerProvider.notifier).refreshPendingCount();
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

  /// Runs an action after every earlier write and forwards its result or error.
  ///
  /// The queue always keeps running, but unlike [_enqueueWrite] this variant
  /// does not hide failures: the edit and delete results must reach the editor.
  Future<T> _enqueueAction<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _writeQueue = _writeQueue.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }
}

final sleepTrackingControllerProvider =
    NotifierProvider<SleepTrackingController, SleepTrackingState>(
      SleepTrackingController.new,
    );
