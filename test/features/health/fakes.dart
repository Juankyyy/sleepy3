import 'package:sleepy3/features/health/domain/health_connect_gateway.dart';
import 'package:sleepy3/features/health/domain/health_sleep_session.dart';

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
