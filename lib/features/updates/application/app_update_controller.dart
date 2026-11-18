import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/application/app_version_provider.dart';
import '../../settings/application/settings_providers.dart';
import '../../sleep_tracking/application/sleep_tracking_providers.dart';
import '../domain/app_release.dart';
import '../domain/app_version_number.dart';
import '../domain/update_prompt_action.dart';
import '../domain/update_prompt_preferences.dart';
import 'update_providers.dart';

export 'update_providers.dart';

enum AppUpdatePhase { idle, checking, upToDate, available, failed }

/// The update check state and the prompt decisions for the current version.
class AppUpdateState {
  const AppUpdateState({
    this.phase = AppUpdatePhase.idle,
    this.release,
    this.pendingPrompt,
    this.preferences = UpdatePromptPreferences.defaults,
  });

  final AppUpdatePhase phase;

  /// The newer release when [phase] is [AppUpdatePhase.available].
  final AppRelease? release;

  /// The release whose dialog must be shown once. It is set only by the
  /// automatic launch check.
  final AppRelease? pendingPrompt;

  final UpdatePromptPreferences preferences;
}

/// Checks GitHub for a newer release and owns the update dialog decisions.
///
/// The launch check runs once per controller lifetime; the Settings row can
/// always force another check. A manual check updates the row but never opens
/// the dialog by itself.
class AppUpdateController extends Notifier<AppUpdateState> {
  Future<void>? _inFlight;
  bool _launchCheckStarted = false;

  @override
  AppUpdateState build() {
    return AppUpdateState(
      preferences: ref.watch(initialUpdatePromptPreferencesProvider),
    );
  }

  /// Runs the automatic check once per app launch.
  Future<void> checkOnLaunch() {
    if (_launchCheckStarted) return Future<void>.value();
    _launchCheckStarted = true;
    return _check(manual: false);
  }

  /// Forces a check from Settings.
  Future<void> checkNow() => _check(manual: true);

  /// Runs the row action: download when a release is available, otherwise
  /// check again. The row's checking state ignores taps.
  Future<bool> handleRowTap() async {
    if (state.phase == AppUpdatePhase.available && state.release != null) {
      return openDownload();
    }
    if (state.phase == AppUpdatePhase.checking) return true;
    await checkNow();
    return true;
  }

  /// Opens the APK asset, falling back to the release page when the release
  /// has no APK. A successful launch marks this version as seen.
  Future<bool> openDownload() async {
    final release = state.release;
    if (release == null) return false;

    final opened = await ref
        .read(updateLinkLauncherProvider)
        .open(release.apkUrl ?? release.pageUrl);
    if (!ref.mounted) return opened;
    if (opened) await _markVersionSeen(release.version);
    return opened;
  }

  /// Opens the GitHub release page. A successful launch marks this version as
  /// seen.
  Future<bool> openReleasePage() async {
    final release = state.release;
    if (release == null) return false;

    final opened = await ref
        .read(updateLinkLauncherProvider)
        .open(release.pageUrl);
    if (!ref.mounted) return opened;
    if (opened) await _markVersionSeen(release.version);
    return opened;
  }

  /// Applies the dialog result. Null (barrier or back) behaves like the close
  /// button and snoozes this version for 24 hours.
  Future<bool> handlePromptAction(UpdatePromptAction? action) async {
    final release = state.pendingPrompt ?? state.release;
    if (release == null) return true;

    switch (action ?? UpdatePromptAction.snooze) {
      case UpdatePromptAction.snooze:
        final until = ref
            .read(sleepClockProvider)()
            .add(const Duration(hours: 24));
        final updated = state.preferences.withSnooze(
          version: release.version,
          until: until,
        );
        state = AppUpdateState(
          phase: state.phase,
          release: state.release,
          preferences: updated,
        );
        await _persist(updated);
        return true;

      case UpdatePromptAction.dismissVersion:
        await _markVersionSeen(release.version);
        return true;

      case UpdatePromptAction.download:
        state = AppUpdateState(
          phase: state.phase,
          release: state.release,
          preferences: state.preferences,
        );
        return openDownload();

      case UpdatePromptAction.openRelease:
        state = AppUpdateState(
          phase: state.phase,
          release: state.release,
          preferences: state.preferences,
        );
        return openReleasePage();
    }
  }

  Future<void> _check({required bool manual}) {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    late final Future<void> future;
    future = _runCheck(manual: manual).whenComplete(() {
      if (identical(_inFlight, future)) _inFlight = null;
    });
    _inFlight = future;
    return future;
  }

  Future<void> _runCheck({required bool manual}) async {
    final installed = ref.read(appVersionProvider);
    if (installed == null) return;

    final installedNumber = AppVersionNumber.tryParse(installed.version);
    if (installedNumber == null) return;

    final preferences = state.preferences;
    final startedAt = manual ? ref.read(sleepClockProvider)() : null;

    state = AppUpdateState(
      phase: AppUpdatePhase.checking,
      preferences: preferences,
    );

    late final AppUpdateState next;
    try {
      final release = await ref.read(appReleaseGatewayProvider).fetchLatest();
      if (!ref.mounted) return;

      final latestNumber = AppVersionNumber.tryParse(release.version);
      if (latestNumber == null) {
        next = AppUpdateState(
          phase: AppUpdatePhase.failed,
          preferences: preferences,
        );
      } else if (!latestNumber.isNewerThan(installedNumber)) {
        next = AppUpdateState(
          phase: AppUpdatePhase.upToDate,
          preferences: preferences,
        );
      } else {
        final now = ref.read(sleepClockProvider)();
        final prompt = !manual && preferences.shouldPrompt(release.version, now)
            ? release
            : null;

        next = AppUpdateState(
          phase: AppUpdatePhase.available,
          release: release,
          pendingPrompt: prompt,
          preferences: preferences,
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Sleepy3: could not check for updates: $error\n$stackTrace');
      if (!ref.mounted) return;
      next = AppUpdateState(
        phase: AppUpdatePhase.failed,
        preferences: preferences,
      );
    }

    if (manual) {
      final minimum = ref.read(manualUpdateCheckMinimumDurationProvider);
      final elapsed = ref.read(sleepClockProvider)().difference(startedAt!);
      final remaining = minimum - elapsed;
      if (remaining > Duration.zero) {
        await Future<void>.delayed(remaining);
        if (!ref.mounted) return;
      }
    }

    state = next;
  }

  Future<void> _markVersionSeen(String version) async {
    final updated = state.preferences.withDismissedVersion(version);
    state = AppUpdateState(
      phase: state.phase,
      release: state.release,
      preferences: updated,
    );
    await _persist(updated);
  }

  Future<void> _persist(UpdatePromptPreferences preferences) async {
    try {
      await ref
          .read(settingsStoreProvider)
          .saveUpdatePromptPreferences(preferences);
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not save update prompt preferences: '
        '$error\n$stackTrace',
      );
    }
  }
}

final appUpdateControllerProvider =
    NotifierProvider<AppUpdateController, AppUpdateState>(
      AppUpdateController.new,
    );
