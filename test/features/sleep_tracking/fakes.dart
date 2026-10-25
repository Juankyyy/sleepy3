import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session_store.dart';

class FakeSleepSessionStore implements SleepSessionStore {
  FakeSleepSessionStore({this.snapshot = SleepSnapshot.empty});

  SleepSnapshot snapshot;
  final starts = <SleepSession>[];
  final finishes = <DateTime>[];
  int loads = 0;

  @override
  Future<SleepSnapshot> load({required DateTime now}) async {
    loads++;
    return snapshot;
  }

  @override
  Future<void> startSession(SleepSession session) async {
    starts.add(session);
  }

  @override
  Future<void> finishOpenSession(DateTime endedAt) async {
    finishes.add(endedAt);
  }
}
