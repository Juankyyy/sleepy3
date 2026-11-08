/// The stable Health Connect client record id Sleepy3 uses for a session.
///
/// It is derived from the original start time so retries and edits update the
/// same platform record instead of creating a duplicate. The v4 migration uses
/// the same format for every local row.
String sleepy3SleepClientRecordId(DateTime startedAt) =>
    'sleepy3-${startedAt.millisecondsSinceEpoch}';
