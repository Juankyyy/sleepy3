import 'sleep_session.dart';

/// The values the session editor changes for one closed session.
///
/// A draft is pure data: it does not read the clock and does not write
/// anything. Callers validate it with [validateSessionEdit] before saving.
class SessionEditDraft {
  const SessionEditDraft({
    required this.startedAt,
    required this.endedAt,
    this.originalStartedAt,
    this.originalEndedAt,
  });

  /// A draft that starts with the session's current times.
  ///
  /// Only closed sessions can be edited; an open session is rejected because
  /// Stats never shows it.
  factory SessionEditDraft.fromSession(SleepSession session) {
    final endedAt = session.endedAt;
    if (endedAt == null) {
      throw ArgumentError.value(session, 'session', 'Session must be closed');
    }
    return SessionEditDraft(
      startedAt: session.startedAt,
      endedAt: endedAt,
      originalStartedAt: session.startedAt,
      originalEndedAt: endedAt,
    );
  }

  final DateTime startedAt;
  final DateTime endedAt;

  /// Times the session had when the editor opened, used for [isDirty].
  final DateTime? originalStartedAt;
  final DateTime? originalEndedAt;

  Duration get duration => endedAt.difference(startedAt);

  /// Whether either time differs from the value the editor opened with.
  bool get isDirty =>
      startedAt != originalStartedAt || endedAt != originalEndedAt;

  SessionEditDraft copyWith({DateTime? startedAt, DateTime? endedAt}) {
    return SessionEditDraft(
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      originalStartedAt: originalStartedAt,
      originalEndedAt: originalEndedAt,
    );
  }
}

/// One problem that prevents saving a [SessionEditDraft].
///
/// The message is shared by the editor and the controller so both explain the
/// same rule with the same words.
enum SessionEditError {
  endNotAfterStart('The wake time must be after the sleep time.'),
  tooShort('A sleep session must be at least 10 minutes.'),
  startInTheFuture('The sleep time cannot be in the future.'),
  endInTheFuture('The wake time cannot be in the future.'),
  overlapsClosedSession('This session overlaps another sleep session.'),
  overlapsOpenSession('This session overlaps the session in progress.');

  const SessionEditError(this.message);

  /// User-facing text in English.
  final String message;
}

/// Every rule a closed-session draft must satisfy, in a stable order.
///
/// The draft must end after it starts, last at least
/// [minimumRecordableSleep], neither time can be in the future, and it cannot
/// overlap another closed session or the open one. Sessions that only touch
/// at an endpoint do not overlap: waking at the same time another session
/// starts is valid.
///
/// [otherClosedSessions] must not include the session being edited. Callers
/// can match it by [SleepSession.localId] or [SleepSession.healthRecordId].
List<SessionEditError> validateSessionEdit({
  required SessionEditDraft draft,
  required DateTime now,
  Iterable<SleepSession> otherClosedSessions = const [],
  SleepSession? openSession,
}) {
  final errors = <SessionEditError>[];

  if (!draft.endedAt.isAfter(draft.startedAt)) {
    errors.add(SessionEditError.endNotAfterStart);
  } else if (draft.duration < minimumRecordableSleep) {
    // A reversed or empty interval already got a clearer error above.
    errors.add(SessionEditError.tooShort);
  }
  if (draft.startedAt.isAfter(now)) {
    errors.add(SessionEditError.startInTheFuture);
  }
  if (draft.endedAt.isAfter(now)) {
    errors.add(SessionEditError.endInTheFuture);
  }

  // A reversed or empty interval cannot overlap anything useful, and the
  // caller already got a clearer error above.
  if (draft.endedAt.isAfter(draft.startedAt)) {
    for (final session in otherClosedSessions) {
      final endedAt = session.endedAt;
      if (endedAt == null) continue;
      if (draft.startedAt.isBefore(endedAt) &&
          session.startedAt.isBefore(draft.endedAt)) {
        errors.add(SessionEditError.overlapsClosedSession);
        break;
      }
    }

    if (openSession != null && draft.endedAt.isAfter(openSession.startedAt)) {
      errors.add(SessionEditError.overlapsOpenSession);
    }
  }

  return List.unmodifiable(errors);
}

/// What the session editor can do with one session.
enum SessionEditAccess {
  /// The session cannot be changed or deleted.
  readOnly,

  /// Both times and deletion are available.
  editAndDelete,
}

/// The editor actions available for [session] in the selected data source.
///
/// Local mode edits rows stored by Sleepy3; downloaded copies stay read-only.
/// In Google Health mode only records written by Sleepy3 are actionable, and
/// [isOwnHealthRecord] carries that ownership check. Every own record with a
/// stable identity can be edited: a local copy with a Health Connect client id,
/// or the Health Connect UUID used to update the record in place.
SessionEditAccess sessionEditAccess(
  SleepSession session, {
  required bool healthConnectSource,
  bool isOwnHealthRecord = false,
}) {
  if (session.isOpen) return SessionEditAccess.readOnly;

  if (!healthConnectSource) {
    return session.isEditableLocal
        ? SessionEditAccess.editAndDelete
        : SessionEditAccess.readOnly;
  }

  if (!isOwnHealthRecord) return SessionEditAccess.readOnly;

  final canEdit =
      session.healthRecordId != null ||
      (session.localId != null && session.healthClientRecordId != null);
  return canEdit ? SessionEditAccess.editAndDelete : SessionEditAccess.readOnly;
}
