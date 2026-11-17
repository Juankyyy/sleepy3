/// What the user chose in the update dialog.
enum UpdatePromptAction {
  /// Close the dialog. The same version is not shown again for 24 hours.
  snooze,

  /// Never show this version's dialog again. A newer version prompts again.
  dismissVersion,

  /// Open the APK download. The version is marked as seen when it succeeds.
  download,

  /// Open the GitHub release page. The version is marked as seen when it
  /// succeeds.
  openRelease,
}
