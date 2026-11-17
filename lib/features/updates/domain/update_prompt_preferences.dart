/// Persisted decisions about the automatic update prompt.
///
/// Both decisions are per version: a newer release prompts again even when the
/// previous one was snoozed or dismissed.
class UpdatePromptPreferences {
  const UpdatePromptPreferences({
    this.dismissedVersion,
    this.snoozedVersion,
    this.snoozedUntil,
  });

  static const defaults = UpdatePromptPreferences();

  /// The version whose dialog must not be shown again.
  final String? dismissedVersion;

  /// The version snoozed by the close button.
  final String? snoozedVersion;

  /// When the snooze for [snoozedVersion] expires.
  final DateTime? snoozedUntil;

  /// Whether a release with [version] should show the dialog at [now].
  bool shouldPrompt(String version, DateTime now) {
    if (dismissedVersion == version) return false;

    final until = snoozedUntil;
    if (snoozedVersion == version && until != null && now.isBefore(until)) {
      return false;
    }
    return true;
  }

  UpdatePromptPreferences withDismissedVersion(String version) {
    return UpdatePromptPreferences(
      dismissedVersion: version,
      snoozedVersion: snoozedVersion,
      snoozedUntil: snoozedUntil,
    );
  }

  UpdatePromptPreferences withSnooze({
    required String version,
    required DateTime until,
  }) {
    return UpdatePromptPreferences(
      dismissedVersion: dismissedVersion,
      snoozedVersion: version,
      snoozedUntil: until,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UpdatePromptPreferences &&
        other.dismissedVersion == dismissedVersion &&
        other.snoozedVersion == snoozedVersion &&
        other.snoozedUntil == snoozedUntil;
  }

  @override
  int get hashCode {
    return Object.hash(dismissedVersion, snoozedVersion, snoozedUntil);
  }

  @override
  String toString() {
    return 'UpdatePromptPreferences('
        'dismissedVersion: $dismissedVersion, '
        'snoozedVersion: $snoozedVersion, '
        'snoozedUntil: $snoozedUntil)';
  }
}
