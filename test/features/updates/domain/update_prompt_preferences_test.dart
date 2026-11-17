import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/updates/domain/update_prompt_preferences.dart';

void main() {
  final now = DateTime(2026, 11, 17, 22);
  final until = now.add(const Duration(hours: 24));

  test('prompts when there is no decision', () {
    expect(UpdatePromptPreferences.defaults.shouldPrompt('0.4.1', now), isTrue);
  });

  test('does not prompt a dismissed version again', () {
    final preferences = UpdatePromptPreferences.defaults.withDismissedVersion(
      '0.4.1',
    );

    expect(preferences.shouldPrompt('0.4.1', now), isFalse);
    expect(preferences.shouldPrompt('0.4.2', now), isTrue);
  });

  test('snoozes only the matching version until the deadline', () {
    final preferences = UpdatePromptPreferences.defaults.withSnooze(
      version: '0.4.1',
      until: until,
    );

    expect(preferences.shouldPrompt('0.4.1', now), isFalse);
    expect(
      preferences.shouldPrompt(
        '0.4.1',
        until.subtract(const Duration(seconds: 1)),
      ),
      isFalse,
    );
    expect(preferences.shouldPrompt('0.4.1', until), isTrue);
    expect(preferences.shouldPrompt('0.4.2', now), isTrue);
  });

  test('keeps the other decision when one field changes', () {
    final snoozed = UpdatePromptPreferences.defaults
        .withSnooze(version: '0.4.1', until: until)
        .withDismissedVersion('0.4.0');

    expect(snoozed.dismissedVersion, '0.4.0');
    expect(snoozed.snoozedVersion, '0.4.1');
    expect(snoozed.snoozedUntil, until);
  });
}
