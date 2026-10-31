import 'dart:async';

import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session_store.dart';

/// In-memory sleep store that also behaves like the Drift store for the
/// start/finish cycle, so a history reload sees what the controller wrote.
class FakeSleepSessionStore implements SleepSessionStore {
  FakeSleepSessionStore({this.snapshot = SleepSnapshot.empty});

  SleepSnapshot snapshot;
  final starts = <SleepSession>[];
  final finishes = <DateTime>[];
  final updates = <SleepSession>[];
  final deletes = <int>[];
  int loads = 0;
  int openLoads = 0;
  int closedLoads = 0;

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
}
