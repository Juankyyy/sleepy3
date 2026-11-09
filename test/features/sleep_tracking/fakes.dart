import 'dart:async';

import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session_store.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleeping_notification_presenter.dart';

/// In-memory sleep store that also behaves like the Drift store for the
/// start/finish cycle, so a history reload sees what the controller wrote.
class FakeSleepSessionStore implements SleepSessionStore {
  FakeSleepSessionStore({this.snapshot = SleepSnapshot.empty});

  SleepSnapshot snapshot;
  final starts = <SleepSession>[];
  final inserted = <SleepSession>[];
  final finishes = <DateTime>[];
  final updates = <SleepSession>[];
  final deletes = <int>[];
  final retimedStarts = <DateTime>[];
  int loads = 0;
  int openLoads = 0;
  int closedLoads = 0;
  int discards = 0;
  int purges = 0;

  /// When set, [loadClosedSessions] waits for it before returning.
  Completer<void>? closedLoadGate;

  /// When set, [loadClosedSessions] throws it.
  Object? closedLoadError;

  @override
  Future<SleepSnapshot> load() async {
    loads++;
    return snapshot;
  }

  @override
  Future<SleepSession?> loadOpenSession() async {
    openLoads++;
    return snapshot.openSession;
  }

  @override
  Future<List<SleepSession>> loadClosedSessions() async {
    closedLoads++;
    final gate = closedLoadGate;
    if (gate != null) await gate.future;
    final error = closedLoadError;
    if (error != null) throw error;
    return snapshot.closedSessions;
  }

  @override
  Future<void> startSession(SleepSession session) async {
    starts.add(session);
    snapshot = SleepSnapshot(
      openSession: session,
      closedSessions: snapshot.closedSessions,
    );
  }

  @override
  Future<SleepSession> insertClosedSession(SleepSession session) async {
    if (session.endedAt == null) {
      throw ArgumentError.value(
        session,
        'session',
        'Only closed sessions can be inserted',
      );
    }

    var nextId = 1;
    for (final current in snapshot.closedSessions) {
      final id = current.localId;
      if (id != null && id >= nextId) nextId = id + 1;
    }

    final insertedSession = session.withLocalId(nextId);
    final next = [...snapshot.closedSessions, insertedSession]
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    snapshot = SleepSnapshot(
      openSession: snapshot.openSession,
      closedSessions: next,
    );
    inserted.add(insertedSession);
    return insertedSession;
  }

  @override
  Future<bool> updateSession(
    int id,
    DateTime startedAt,
    DateTime endedAt, {
    bool markHealthPending = true,
  }) async {
    final sessions = snapshot.closedSessions;
    final index = sessions.indexWhere(
      (session) => session.localId == id && !session.isDownloaded,
    );
    if (index == -1) return false;

    final previous = sessions[index];
    final updated = SleepSession(
      startedAt: startedAt,
      endedAt: endedAt,
      localId: previous.localId,
      isDownloaded: previous.isDownloaded,
      healthRecordId: previous.healthRecordId,
      healthClientRecordId: previous.healthClientRecordId,
      sourceId: previous.sourceId,
    );
    final next = [...sessions]..[index] = updated;
    snapshot = SleepSnapshot(
      openSession: snapshot.openSession,
      closedSessions: next,
    );
    updates.add(updated);
    return true;
  }

  @override
  Future<bool> deleteSession(int id) async {
    final sessions = snapshot.closedSessions;
    final index = sessions.indexWhere(
      (session) => session.localId == id && !session.isDownloaded,
    );
    if (index == -1) return false;

    final next = [...sessions]..removeAt(index);
    snapshot = SleepSnapshot(
      openSession: snapshot.openSession,
      closedSessions: next,
    );
    deletes.add(id);
    return true;
  }

  @override
  Future<void> finishOpenSession(DateTime endedAt) async {
    finishes.add(endedAt);
    final open = snapshot.openSession;
    if (open == null) return;
    snapshot = SleepSnapshot(
      closedSessions: [...snapshot.closedSessions, open.finish(endedAt)],
    );
  }

  @override
  Future<void> discardOpenSession() async {
    discards++;
    snapshot = SleepSnapshot(closedSessions: snapshot.closedSessions);
  }

  @override
  Future<bool> updateOpenSessionStart(DateTime startedAt) async {
    final open = snapshot.openSession;
    if (open == null) return false;
    retimedStarts.add(startedAt);
    snapshot = SleepSnapshot(
      openSession: open.retimeStart(startedAt),
      closedSessions: snapshot.closedSessions,
    );
    return true;
  }

  @override
  Future<int> purgeUnrecordableSessions(
    Duration minimum,
    Duration maximum,
  ) async {
    purges++;
    final kept = <SleepSession>[];
    var purged = 0;

    for (final session in snapshot.closedSessions) {
      final unpublished =
          session.endedAt != null &&
          !session.isDownloaded &&
          session.healthRecordId == null;
      final duration = session.duration;
      final unrecordable = duration < minimum || duration >= maximum;
      if (unpublished && unrecordable) {
        purged++;
        continue;
      }
      kept.add(session);
    }

    snapshot = SleepSnapshot(
      openSession: snapshot.openSession,
      closedSessions: kept,
    );
    return purged;
  }
}

class ShownSleepingNotification {
  const ShownSleepingNotification({
    required this.startedAt,
    required this.copy,
  });

  final DateTime startedAt;
  final SleepingNotificationCopy copy;
}

class FakeSleepingNotificationPresenter
    implements SleepingNotificationPresenter {
  FakeSleepingNotificationPresenter({
    this.notificationsAreEnabled = true,
    this.permissionGranted = true,
    this.throwOnShow = false,
    this.throwOnCancel = false,
  });

  bool notificationsAreEnabled;
  bool permissionGranted;
  bool throwOnShow;
  bool throwOnCancel;

  int notificationsEnabledChecks = 0;
  int permissionRequests = 0;
  int cancels = 0;
  int openSettingsCalls = 0;
  final shown = <ShownSleepingNotification>[];
  final events = <String>[];

  @override
  Future<bool> notificationsEnabled() async {
    notificationsEnabledChecks++;
    return notificationsAreEnabled;
  }

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<void> show({
    required DateTime startedAt,
    required SleepingNotificationCopy copy,
  }) async {
    if (throwOnShow) throw StateError('show failed');
    shown.add(ShownSleepingNotification(startedAt: startedAt, copy: copy));
    events.add('show');
  }

  @override
  Future<void> cancel() async {
    if (throwOnCancel) throw StateError('cancel failed');
    cancels++;
    events.add('cancel');
  }

  @override
  Future<void> openNotificationSettings() async {
    openSettingsCalls++;
  }
}
