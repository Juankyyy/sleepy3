import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show GlobalMaterialLocalizations;

import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

/// The delegates for the Sleepy3 Material app.
///
/// `material_ui` carries its own `MaterialLocalizations` type, so the global
/// Material and Cupertino delegates must come from that package. The generated
/// list uses `flutter_localizations` instead, which does not satisfy the
/// `MaterialLocalizations` lookup in `M3EMaterialApp`.
final appLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];

/// Shorthand for the generated Sleepy3 strings.
extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Sleep duration labels shared by Home, Stats and the session editor.
///
/// The compact form is used in cards and rows (`7h 45m` / `7 h 45 min`); the
/// spoken form is used in accessibility labels.
extension SleepDurationLocalizations on AppLocalizations {
  String formatSleepDuration(Duration duration) {
    final safe = duration.isNegative ? Duration.zero : duration;
    final hours = safe.inHours;
    final minutes = safe.inMinutes.remainder(60);
    if (hours == 0) return durationMinutes(minutes);
    return durationHoursMinutes(hours, minutes);
  }

  String formatSpokenSleepDuration(Duration duration) {
    final safe = duration.isNegative ? Duration.zero : duration;
    final hours = safe.inHours;
    final minutes = safe.inMinutes.remainder(60);
    if (hours == 0) return spokenDurationMinutes(minutes);
    return spokenDurationHoursMinutes(hours, minutes);
  }

  /// A goal delta without a zero minute part: `13m`, `1h`, `1h 12m`.
  String formatGoalDelta(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours == 0) return durationMinutes(minutes);
    if (minutes == 0) return durationHours(hours);
    return durationHoursMinutes(hours, minutes);
  }

  /// A signed compact duration: `+18m`, `−1h 12m` or `0m`.
  ///
  /// The sign is part of the copy so a debt never depends on color alone.
  String formatSignedCompactDuration(Duration duration) {
    if (duration == Duration.zero) return formatGoalDelta(duration);
    final formatted = formatGoalDelta(duration.abs());
    return duration.isNegative
        ? durationSignedNegative(formatted)
        : durationSignedPositive(formatted);
  }
}
