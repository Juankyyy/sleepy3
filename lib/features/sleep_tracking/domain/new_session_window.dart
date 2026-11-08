/// The initial times offered when a session is added by hand.
///
/// The window is the last typical night: 23:00 to 07:00. Before 07:00 the
/// wake time is [now] instead, so a session can be added right after waking
/// (or during the night) without an end in the future.
///
/// This is a Sleepy3 design decision, not a rule from Health Connect.
class NewSessionWindow {
  const NewSessionWindow({required this.startedAt, required this.endedAt});

  final DateTime startedAt;
  final DateTime endedAt;
}

/// The last night's window at [now], ready for the new-session editor.
///
/// Both values are local and have minute precision. The duration is always
/// between one and eight hours, so the draft starts inside the recordable
/// range; the editor still validates it like any other draft.
NewSessionWindow defaultNewSessionWindow(DateTime now) {
  final local = now.toLocal();
  final endedAt = local.hour >= 7
      ? DateTime(local.year, local.month, local.day, 7)
      : DateTime(local.year, local.month, local.day, local.hour, local.minute);
  final startedAt = DateTime(endedAt.year, endedAt.month, endedAt.day - 1, 23);
  return NewSessionWindow(startedAt: startedAt, endedAt: endedAt);
}
