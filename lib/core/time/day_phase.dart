/// The day/night split used by the Home header and the no-session copy.
///
/// M3 defines no day boundary. The prototype does: day runs from 07:00 to
/// 18:59 and night from 19:00 to 06:59.
enum DayPhase {
  /// 07:00–18:59.
  day,

  /// 19:00–06:59.
  night,
}

/// Returns the [DayPhase] for [time], using the prototype's 07:00/19:00 rule.
///
/// This is a product rule, not an M3 token. The clock is local time, so the
/// boundary follows the device's time zone.
DayPhase dayPhaseFor(DateTime time) =>
    time.hour >= 7 && time.hour < 19 ? DayPhase.day : DayPhase.night;
