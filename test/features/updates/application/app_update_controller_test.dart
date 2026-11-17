import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/settings/application/app_version_provider.dart';
import 'package:sleepy3/features/settings/application/settings_providers.dart';
import 'package:sleepy3/features/settings/domain/app_version.dart';
import 'package:sleepy3/features/sleep_tracking/application/sleep_tracking_providers.dart';
import 'package:sleepy3/features/updates/application/app_update_controller.dart';
import 'package:sleepy3/features/updates/domain/app_release.dart';
import 'package:sleepy3/features/updates/domain/update_prompt_action.dart';
import 'package:sleepy3/features/updates/domain/update_prompt_preferences.dart';

import '../../settings/fakes.dart';
import '../fakes.dart';

void main() {
  final now = DateTime(2026, 11, 17, 22);

  ProviderContainer container({
    required FakeAppReleaseGateway gateway,
    required FakeUpdateLinkLauncher launcher,
    required FakeSettingsStore store,
    AppVersion? version = const AppVersion(version: '0.3.1'),
    UpdatePromptPreferences preferences = UpdatePromptPreferences.defaults,
  }) {
    final container = ProviderContainer(
      overrides: [
        appVersionProvider.overrideWithValue(version),
        appReleaseGatewayProvider.overrideWithValue(gateway),
        updateLinkLauncherProvider.overrideWithValue(launcher),
        settingsStoreProvider.overrideWithValue(store),
        initialUpdatePromptPreferencesProvider.overrideWithValue(preferences),
        sleepClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('the launch check prompts when a newer release is available', () async {
    final gateway = FakeAppReleaseGateway(testRelease('0.4.0'));
    final store = FakeSettingsStore();
    final app = container(
      gateway: gateway,
      launcher: FakeUpdateLinkLauncher(),
      store: store,
    );

    await app.read(appUpdateControllerProvider.notifier).checkOnLaunch();
    final state = app.read(appUpdateControllerProvider);

    expect(state.phase, AppUpdatePhase.available);
    expect(state.release?.version, '0.4.0');
    expect(state.pendingPrompt?.version, '0.4.0');
    expect(gateway.calls, 1);
  });

  test('the launch check runs only once per launch', () async {
    final gateway = FakeAppReleaseGateway(testRelease('0.4.0'));
    final app = container(
      gateway: gateway,
      launcher: FakeUpdateLinkLauncher(),
      store: FakeSettingsStore(),
    );

    final controller = app.read(appUpdateControllerProvider.notifier);
    await controller.checkOnLaunch();
    await controller.checkOnLaunch();

    expect(gateway.calls, 1);
  });

  test('a manual check updates the row without opening the dialog', () async {
    final gateway = FakeAppReleaseGateway(testRelease('0.4.0'));
    final app = container(
      gateway: gateway,
      launcher: FakeUpdateLinkLauncher(),
      store: FakeSettingsStore(),
    );

    await app.read(appUpdateControllerProvider.notifier).checkNow();
    final state = app.read(appUpdateControllerProvider);

    expect(state.phase, AppUpdatePhase.available);
    expect(state.pendingPrompt, isNull);
  });

  test('reports up to date and never goes backwards', () async {
    final upToDate = container(
      gateway: FakeAppReleaseGateway(testRelease('0.3.1')),
      launcher: FakeUpdateLinkLauncher(),
      store: FakeSettingsStore(),
    );
    await upToDate.read(appUpdateControllerProvider.notifier).checkOnLaunch();
    expect(
      upToDate.read(appUpdateControllerProvider).phase,
      AppUpdatePhase.upToDate,
    );

    final installedNewer = container(
      gateway: FakeAppReleaseGateway(testRelease('0.3.1')),
      launcher: FakeUpdateLinkLauncher(),
      store: FakeSettingsStore(),
      version: const AppVersion(version: '0.4.0'),
    );
    await installedNewer
        .read(appUpdateControllerProvider.notifier)
        .checkOnLaunch();
    expect(
      installedNewer.read(appUpdateControllerProvider).phase,
      AppUpdatePhase.upToDate,
    );
  });

  test('reports a failed check', () async {
    final gateway = FakeAppReleaseGateway()..error = StateError('offline');
    final app = container(
      gateway: gateway,
      launcher: FakeUpdateLinkLauncher(),
      store: FakeSettingsStore(),
    );

    await app.read(appUpdateControllerProvider.notifier).checkOnLaunch();

    expect(app.read(appUpdateControllerProvider).phase, AppUpdatePhase.failed);
  });

  test('skips the check without a usable installed version', () async {
    for (final version in <AppVersion?>[
      null,
      const AppVersion(version: 'dev'),
    ]) {
      final gateway = FakeAppReleaseGateway(testRelease('0.4.0'));
      final app = container(
        gateway: gateway,
        launcher: FakeUpdateLinkLauncher(),
        store: FakeSettingsStore(),
        version: version,
      );

      await app.read(appUpdateControllerProvider.notifier).checkOnLaunch();

      expect(app.read(appUpdateControllerProvider).phase, AppUpdatePhase.idle);
      expect(gateway.calls, 0);
    }
  });

  test(
    'does not prompt a dismissed version but prompts the next one',
    () async {
      final store = FakeSettingsStore(
        updatePromptPreferences: UpdatePromptPreferences.defaults
            .withDismissedVersion('0.4.1'),
      );
      final app = container(
        gateway: FakeAppReleaseGateway(testRelease('0.4.1')),
        launcher: FakeUpdateLinkLauncher(),
        store: store,
        preferences: store.updatePromptPreferences,
      );

      await app.read(appUpdateControllerProvider.notifier).checkOnLaunch();
      expect(app.read(appUpdateControllerProvider).pendingPrompt, isNull);

      final next = container(
        gateway: FakeAppReleaseGateway(testRelease('0.4.2')),
        launcher: FakeUpdateLinkLauncher(),
        store: FakeSettingsStore(
          updatePromptPreferences: UpdatePromptPreferences.defaults
              .withDismissedVersion('0.4.1'),
        ),
        preferences: UpdatePromptPreferences.defaults.withDismissedVersion(
          '0.4.1',
        ),
      );

      await next.read(appUpdateControllerProvider.notifier).checkOnLaunch();
      expect(
        next.read(appUpdateControllerProvider).pendingPrompt?.version,
        '0.4.2',
      );
    },
  );

  test('a snoozed version waits 24 hours, a newer one does not', () async {
    final until = now.add(const Duration(hours: 24));
    final snoozed = UpdatePromptPreferences.defaults.withSnooze(
      version: '0.4.1',
      until: until,
    );
    final app = container(
      gateway: FakeAppReleaseGateway(testRelease('0.4.1')),
      launcher: FakeUpdateLinkLauncher(),
      store: FakeSettingsStore(updatePromptPreferences: snoozed),
      preferences: snoozed,
    );

    await app.read(appUpdateControllerProvider.notifier).checkOnLaunch();
    expect(app.read(appUpdateControllerProvider).pendingPrompt, isNull);

    final newer = container(
      gateway: FakeAppReleaseGateway(testRelease('0.4.2')),
      launcher: FakeUpdateLinkLauncher(),
      store: FakeSettingsStore(updatePromptPreferences: snoozed),
      preferences: snoozed,
    );
    await newer.read(appUpdateControllerProvider.notifier).checkOnLaunch();
    expect(
      newer.read(appUpdateControllerProvider).pendingPrompt?.version,
      '0.4.2',
    );
  });

  test('the close action snoozes this version for 24 hours', () async {
    final store = FakeSettingsStore();
    final app = container(
      gateway: FakeAppReleaseGateway(testRelease('0.4.0')),
      launcher: FakeUpdateLinkLauncher(),
      store: store,
    );

    await app.read(appUpdateControllerProvider.notifier).checkOnLaunch();
    await app
        .read(appUpdateControllerProvider.notifier)
        .handlePromptAction(null);

    final state = app.read(appUpdateControllerProvider);
    expect(state.pendingPrompt, isNull);
    expect(store.updatePromptPreferences.snoozedVersion, '0.4.0');
    expect(
      store.updatePromptPreferences.snoozedUntil,
      now.add(const Duration(hours: 24)),
    );
  });

  test('No recordar dismisses only this version', () async {
    final store = FakeSettingsStore();
    final app = container(
      gateway: FakeAppReleaseGateway(testRelease('0.4.0')),
      launcher: FakeUpdateLinkLauncher(),
      store: store,
    );

    await app.read(appUpdateControllerProvider.notifier).checkOnLaunch();
    await app
        .read(appUpdateControllerProvider.notifier)
        .handlePromptAction(UpdatePromptAction.dismissVersion);

    expect(store.updatePromptPreferences.dismissedVersion, '0.4.0');
    expect(app.read(appUpdateControllerProvider).pendingPrompt, isNull);
  });

  test('downloading opens the APK and marks the version seen', () async {
    final launcher = FakeUpdateLinkLauncher();
    final store = FakeSettingsStore();
    final release = testRelease('0.4.0');
    final app = container(
      gateway: FakeAppReleaseGateway(release),
      launcher: launcher,
      store: store,
    );

    await app.read(appUpdateControllerProvider.notifier).checkOnLaunch();
    final opened = await app
        .read(appUpdateControllerProvider.notifier)
        .handlePromptAction(UpdatePromptAction.download);

    expect(opened, isTrue);
    expect(launcher.uris, [release.apkUrl]);
    expect(store.updatePromptPreferences.dismissedVersion, '0.4.0');
  });

  test('opening GitHub marks the version seen', () async {
    final launcher = FakeUpdateLinkLauncher();
    final store = FakeSettingsStore();
    final release = testRelease('0.4.0');
    final app = container(
      gateway: FakeAppReleaseGateway(release),
      launcher: launcher,
      store: store,
    );

    await app.read(appUpdateControllerProvider.notifier).checkOnLaunch();
    final opened = await app
        .read(appUpdateControllerProvider.notifier)
        .handlePromptAction(UpdatePromptAction.openRelease);

    expect(opened, isTrue);
    expect(launcher.uris, [release.pageUrl]);
    expect(store.updatePromptPreferences.dismissedVersion, '0.4.0');
  });

  test('a failed link leaves the version available for a retry', () async {
    final launcher = FakeUpdateLinkLauncher(result: false);
    final store = FakeSettingsStore();
    final app = container(
      gateway: FakeAppReleaseGateway(testRelease('0.4.0')),
      launcher: launcher,
      store: store,
    );

    await app.read(appUpdateControllerProvider.notifier).checkOnLaunch();
    final opened = await app
        .read(appUpdateControllerProvider.notifier)
        .handlePromptAction(UpdatePromptAction.download);

    expect(opened, isFalse);
    expect(store.updatePromptPreferences.dismissedVersion, isNull);
    expect(
      app.read(appUpdateControllerProvider).phase,
      AppUpdatePhase.available,
    );
  });

  test('the row downloads an available release and checks otherwise', () async {
    final launcher = FakeUpdateLinkLauncher();
    final gateway = FakeAppReleaseGateway(testRelease('0.4.0'));
    final app = container(
      gateway: gateway,
      launcher: launcher,
      store: FakeSettingsStore(),
    );
    final controller = app.read(appUpdateControllerProvider.notifier);

    await controller.handleRowTap();
    expect(gateway.calls, 1);
    expect(launcher.uris, isEmpty);

    final opened = await controller.handleRowTap();
    expect(opened, isTrue);
    expect(launcher.uris, [testRelease('0.4.0').apkUrl]);
  });

  test('a second check joins the in-flight request', () async {
    final gateway = FakeAppReleaseGateway()..pending = Completer<AppRelease>();
    final app = container(
      gateway: gateway,
      launcher: FakeUpdateLinkLauncher(),
      store: FakeSettingsStore(),
    );
    final controller = app.read(appUpdateControllerProvider.notifier);

    final first = controller.checkOnLaunch();
    final second = controller.checkNow();
    expect(gateway.calls, 1);

    gateway.pending!.complete(testRelease('0.4.0'));
    await Future.wait([first, second]);

    expect(
      app.read(appUpdateControllerProvider).phase,
      AppUpdatePhase.available,
    );
  });
}
