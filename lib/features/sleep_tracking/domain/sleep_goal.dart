/// The nightly goal used by Home and Stats to compare a night's duration.
///
/// Sleepy3's design decision, not an M3 token: the Home summary and the Stats
/// goal ring both measure a night against this value.
const dailySleepGoal = Duration(hours: 8);
