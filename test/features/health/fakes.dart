import 'package:sleepy3/features/health/domain/health_connect_gateway.dart';
import 'package:sleepy3/features/health/domain/health_sleep_session.dart';
import 'package:sleepy3/features/health/domain/health_sync_store.dart';
import 'package:sleepy3/features/health/domain/stored_sleep_session.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';

/// One call recorded by [FakeHealthConnectGateway.writeSleepSession].
class RecordedSleepWrite {
  const RecordedSleepWrite({
    required this.startedAt,
    required this.endedAt,
    required this.clientRecordId,
  });

  final DateTime startedAt;
  final DateTime endedAt;
  final String clientRecordId;
}

/// In-memory Health Connect gateway for controller, store and widget tests.
///
/// It mirrors the production rules that matter to the app: unavailable
/// platforms deny access, a permission request grants only what the test
/// configures, and writing twice with the same `clientRecordId` updates the
/// same record instead of creating a duplicate.
class FakeHealthConnectGateway implements HealthConnectGateway {
  FakeHealthConnectGateway({
    this.availability = HealthConnectAvailability.available,
    this.readPermission = true,
    this.writePermission = true,
    this.historyPermission = false,
    this.grantReadOnRequest = true,
    this.grantWriteOnRequest = true,
    this.grantHistoryOnRequest = true,
    this.writeSucceeds = true,
    List<HealthSleepSession> sessions = const [],
  }) : sessions = [...sessions];

  HealthConnectAvailability availability;

  bool readPermission;
  bool writePermission;
  bool historyPermission;

  /// What a permission dialog grants. Set these to false to test denials.
  bool grantReadOnRequest;
  bool grantWriteOnRequest;
  bool grantHistoryOnRequest;

  /// When false, [writeSleepSession] returns null without touching [sessions].
  bool writeSucceeds;

  /// Sessions that throw instead of being written, for partial-failure tests.
  final Set<DateTime> failWriteStarts = {};

  /// Every session currently in Health Connect, from any app.
  final List<HealthSleepSession> sessions;

  /// Every write call, including failed and repeated ones.
  final List<RecordedSleepWrite> writes = [];

  Object? readError;
  Object? writeError;
  Object? permissionError;

  int installCalls = 0;
  int permissionRequestCalls = 0;
  int historyPermissionRequestCalls = 0;
  DateTime? lastReadFrom;
  DateTime? lastReadTo;

  @override
  Future<HealthConnectAvailability> checkAvailability() async => availability;

  @override
  Future<bool> hasPermissions({bool read = true, bool write = false}) async {
    if (!read && !write) return true;
    if (availability != HealthConnectAvailability.available) return false;
    return (!read || readPermission) && (!write || writePermission);
  }

  @override
  Future<bool> requestPermissions({
    bool read = true,
    bool write = false,
  }) async {
    permissionRequestCalls++;
    final error = permissionError;
    if (error != null) throw error;
    if (availability != HealthConnectAvailability.available) return false;

    if (read) readPermission = grantReadOnRequest;
    if (write) writePermission = grantWriteOnRequest;
    return (!read || readPermission) && (!write || writePermission);
  }

  @override
  Future<bool> requestHistoryPermission() async {
    historyPermissionRequestCalls++;
    if (availability != HealthConnectAvailability.available) return false;
    if (historyPermission) return true;

    historyPermission = grantHistoryOnRequest;
    return historyPermission;
  }

  @override
  Future<bool> isHistoryAuthorized() async => historyPermission;

  @override
  Future<List<HealthSleepSession>> readSleepSessions({
    required DateTime from,
    required DateTime to,
  }) async {
    lastReadFrom = from;
    lastReadTo = to;
    final error = readError;
    if (error != null) throw error;
    if (availability != HealthConnectAvailability.available) {
      throw StateError('Health Connect is not available');
    }

    return [
      for (final session in sessions)
        if (session.endedAt.isAfter(from) && session.startedAt.isBefore(to))
          session,
    ]..sort((a, b) => a.startedAt.compareTo(b.startedAt));
  }

  @override
  Future<String?> writeSleepSession({
    required DateTime startedAt,
    required DateTime endedAt,
    required String clientRecordId,
  }) async {
    writes.add(
      RecordedSleepWrite(
        startedAt: startedAt,
        endedAt: endedAt,
        clientRecordId: clientRecordId,
      ),
    );
    final error = writeError;
    if (error != null) throw error;
    if (failWriteStarts.contains(startedAt)) {
      throw StateError('write failed');
    }
    if (availability != HealthConnectAvailability.available) {
      throw StateError('Health Connect is not available');
    }
    if (!writeSucceeds) return null;

    final uuid = 'fake-$clientRecordId';
    final index = sessions.indexWhere((session) => session.uuid == uuid);
    final written = HealthSleepSession(
      uuid: uuid,
      startedAt: startedAt,
      endedAt: endedAt,
      sourceId: 'com.sleepy3.app',
      sourceName: 'Sleepy3',
    );
    if (index == -1) {
      sessions.add(written);
    } else {
      sessions[index] = written;
    }
    return uuid;
  }

  @override
  Future<void> installHealthConnect() async {
    installCalls++;
  }
}

/// In-memory [HealthSyncStore] for controller and widget tests.
///
/// Times are compared in milliseconds, matching the Drift columns, so a test
/// can seed the row the local store would have closed.
class FakeHealthSyncStore implements HealthSyncStore {
  FakeHealthSyncStore({List<StoredSleepSession> rows = const []})
    : rows = [...rows] {
    _nextId = rows.fold(0, (max, row) => row.id > max ? row.id : max) + 1;
  }

  final List<StoredSleepSession> rows;

  /// When set, every read throws it.
  Object? loadError;

  /// Sessions that throw instead of being inserted, for partial failures.
  final Set<DateTime> failInsertStarts = {};

  int pendingCountLoads = 0;
  final markedUploaded = <int>[];
  final markedSkipped = <int>[];

  late int _nextId;

  /// Adds a local row, as if [SleepSessionStore.finishOpenSession] had closed
  /// it in Drift.
  StoredSleepSession addLocal(
    SleepSession session, {
    bool synced = false,
    DateTime? syncedAt,
    bool skipped = false,
    String? healthRecordId,
    int? id,
  }) {
    final rowId = id ?? _nextId++;
    final row = StoredSleepSession(
      id: rowId,
      session: session,
      healthRecordId: healthRecordId,
      healthSyncedAt: synced ? (syncedAt ?? DateTime(2026, 10, 21, 7)) : null,
      healthSyncSkipped: skipped,
    );
    rows.add(row);
    if (rowId >= _nextId) _nextId = rowId + 1;
    return row;
  }

  void _throwIfFailed() {
    final error = loadError;
    if (error != null) throw error;
  }

  @override
  Future<List<StoredSleepSession>> loadPendingUploads() async {
    _throwIfFailed();
    final pending = rows.where((row) => row.isPendingUpload).toList()
      ..sort((a, b) {
        final byStart = a.session.startedAt.compareTo(b.session.startedAt);
        return byStart != 0 ? byStart : a.id.compareTo(b.id);
      });
    return pending;
  }

  @override
  Future<StoredSleepSession?> loadLatestPendingUpload() async {
    final pending = await loadPendingUploads();
    return pending.isEmpty ? null : pending.last;
  }

  @override
  Future<void> markUploaded(
    int rowId,
    String healthRecordId,
    DateTime syncedAt,
  ) async {
    _replace(
      rowId,
      (row) => StoredSleepSession(
        id: row.id,
        session: row.session,
        healthRecordId: healthRecordId,
        healthSyncedAt: syncedAt,
        healthSyncSkipped: row.healthSyncSkipped,
        origin: row.origin,
      ),
    );
    markedUploaded.add(rowId);
  }

  @override
  Future<void> markSkipped(int rowId) async {
    _replace(
      rowId,
      (row) => StoredSleepSession(
        id: row.id,
        session: row.session,
        healthRecordId: row.healthRecordId,
        healthSyncedAt: row.healthSyncedAt,
        healthSyncSkipped: true,
        origin: row.origin,
      ),
    );
    markedSkipped.add(rowId);
  }

  @override
  Future<StoredSleepSession?> findByHealthRecordId(
    String healthRecordId,
  ) async {
    for (final row in rows) {
      if (row.healthRecordId == healthRecordId) return row;
    }
    return null;
  }

  @override
  Future<StoredSleepSession?> findByExactTimes(
    DateTime startedAt,
    DateTime endedAt,
  ) async {
    for (final row in rows) {
      final session = row.session;
      final sessionEnd = session.endedAt;
      if (session.startedAt.millisecondsSinceEpoch ==
              startedAt.millisecondsSinceEpoch &&
          sessionEnd != null &&
          sessionEnd.millisecondsSinceEpoch == endedAt.millisecondsSinceEpoch) {
        return row;
      }
    }
    return null;
  }

  @override
  Future<int> insertDownloaded(
    SleepSession session,
    String? healthRecordId,
    DateTime syncedAt,
  ) async {
    final endedAt = session.endedAt;
    if (endedAt == null) {
      throw ArgumentError.value(
        session,
        'session',
        'Downloaded sessions must be closed',
      );
    }
    if (failInsertStarts.contains(session.startedAt)) {
      throw StateError('insert failed');
    }
    final id = _nextId++;
    rows.add(
      StoredSleepSession(
        id: id,
        session: session,
        healthRecordId: healthRecordId,
        healthSyncedAt: syncedAt,
        origin: SleepSessionOrigin.healthConnect,
      ),
    );
    return id;
  }

  @override
  Future<bool> updateDownloaded(
    int rowId,
    DateTime startedAt,
    DateTime endedAt,
  ) async {
    final index = rows.indexWhere((row) => row.id == rowId);
    if (index == -1) return false;
    final row = rows[index];
    if (row.origin != SleepSessionOrigin.healthConnect) return false;
    rows[index] = StoredSleepSession(
      id: row.id,
      session: SleepSession(startedAt: startedAt, endedAt: endedAt),
      healthRecordId: row.healthRecordId,
      healthSyncedAt: row.healthSyncedAt,
      healthSyncSkipped: row.healthSyncSkipped,
      origin: row.origin,
    );
    return true;
  }

  @override
  Future<int> loadPendingCount() async {
    pendingCountLoads++;
    _throwIfFailed();
    return rows.where((row) => row.isPendingUpload).length;
  }

  void _replace(
    int rowId,
    StoredSleepSession Function(StoredSleepSession row) update,
  ) {
    final index = rows.indexWhere((row) => row.id == rowId);
    if (index == -1) throw StateError('No row with id $rowId');
    rows[index] = update(rows[index]);
  }
}
