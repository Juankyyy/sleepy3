import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/sleepy3_theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../health/application/sleep_data_source_controller.dart';
import '../../../health/presentation/sleep_data_source_text.dart';
import '../../../updates/application/app_update_controller.dart';
import '../../application/app_version_provider.dart';
import '../../domain/app_version.dart';
import 'bento/bento_figure.dart';
import 'bento/settings_tones.dart';
import 'github_mark.dart';

/// The About card at the bottom of Settings.
///
/// It replaces the old Privacy, Version, Check for updates and Licenses rows.
/// The visible version omits the build number; the license page still receives
/// the full `display` value for diagnostics.
class AboutCard extends ConsumerWidget {
  const AboutCard({super.key});

  static final repositoryUri = Uri.parse('https://github.com/Juankyyy/sleepy3');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final tone = SettingsPalette.of(context).about;
    final version = ref.watch(appVersionProvider);
    final dataSource = ref.watch(sleepDataSourceProvider);
    final update = ref.watch(appUpdateControllerProvider);

    final statusStyle = theme.typography.baseline.bodySmall.copyWith(
      color: tone.supporting,
    );
    final versionStyle = theme.typography.baseline.bodySmall.copyWith(
      color: tone.supporting,
    );

    return Material(
      key: const ValueKey('settings-about-card'),
      color: tone.background,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: BentoFigure(
              shape: BentoFigureShape.clover4Leaf,
              color: tone.blob,
              placement: BentoFigurePlacement.wide,
              widthFactor: 0.62,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Sleepy3Theme.lightBackground,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Image.asset(
                          'assets/brand/Sleepy3-mark.png',
                          width: 28,
                          height: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              'Sleepy3',
                              style: Sleepy3Theme.brandTitle(
                                theme.typography.emphasized.headlineSmall,
                              ).copyWith(color: tone.onBackground),
                            ),
                          ),
                          if (version != null) ...[
                            const SizedBox(height: 2),
                            Semantics(
                              container: true,
                              excludeSemantics: true,
                              label: '${l10n.version}, ${version.version}',
                              child: Text(
                                l10n.versionValue(version.version),
                                style: versionStyle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (version != null) ...[
                  const SizedBox(height: 12),
                  _UpdateButton(update: update),
                  const SizedBox(height: 8),
                  _StatusLine(update: update, version: version),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Keep the label and the tap action on the icon button: its
                    // Semantics node is not a boundary and would otherwise merge
                    // into the About card.
                    MergeSemantics(
                      child: M3EIconButton(
                        key: const ValueKey('settings-about-repository'),
                        icon: const GithubMark(),
                        variant: M3EIconButtonVariant.outlined,
                        size: M3EIconButtonSize.sm,
                        tooltip: l10n.openRepository,
                        semanticLabel: l10n.openRepository,
                        onPressed: () => _openRepository(context, ref),
                      ),
                    ),
                    M3EButton.icon(
                      style: M3EButtonStyle.text,
                      icon: const Icon(M3EIcons.description_outlined, size: 18),
                      label: Text(l10n.licenses),
                      onPressed: () => _showLicenses(context, version),
                    ),
                  ],
                ),
                if (version != null) ...[
                  const SizedBox(height: 10),
                  Text(l10n.aboutUpdatesNote, style: statusStyle),
                ],
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      M3EIcons.shield_outlined,
                      size: 16,
                      color: tone.supporting,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.sleepDataSourcePrivacy(dataSource),
                        style: statusStyle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRepository(BuildContext context, WidgetRef ref) async {
    final opened = await ref
        .read(updateLinkLauncherProvider)
        .open(repositoryUri);
    if (!context.mounted || opened) return;
    _showLinkFailure(context);
  }

  void _showLicenses(BuildContext context, AppVersion? version) {
    showLicensePage(
      context: context,
      applicationName: 'Sleepy3',
      applicationVersion: version?.display,
      applicationLegalese: 'GNU General Public License v3.0',
    );
  }

  void _showLinkFailure(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.l10n.updateOpenFailed)));
  }
}

class _UpdateButton extends ConsumerWidget {
  const _UpdateButton({required this.update});

  final AppUpdateState update;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final checking = update.phase == AppUpdatePhase.checking;
    final available = update.phase == AppUpdatePhase.available;

    Future<void> checkAgain() async {
      await ref.read(appUpdateControllerProvider.notifier).checkNow();
    }

    Future<void> primaryAction() async {
      final opened = await ref
          .read(appUpdateControllerProvider.notifier)
          .handleRowTap();
      if (!context.mounted || opened) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(context.l10n.updateOpenFailed)));
    }

    if (available) {
      return Row(
        children: [
          // The icon button's Semantics node is not a boundary; merge it so the
          // label and tap stay on the button instead of the About card.
          MergeSemantics(
            child: M3EIconButton(
              key: const ValueKey('settings-about-update-check'),
              icon: const Icon(M3EIcons.refresh),
              variant: M3EIconButtonVariant.outlined,
              size: M3EIconButtonSize.sm,
              tooltip: l10n.updateCheckTitle,
              semanticLabel: l10n.updateCheckTitle,
              onPressed: checkAgain,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: M3EButton.icon(
              style: M3EButtonStyle.filled,
              icon: const Icon(M3EIcons.download_outlined, size: 18),
              label: Text(l10n.updateDownload),
              onPressed: primaryAction,
            ),
          ),
        ],
      );
    }

    final label = checking ? l10n.updateCheckingShort : l10n.updateCheckTitle;
    final icon = checking
        ? const SizedBox(
            width: 24,
            height: 24,
            child: M3ELoadingIndicator(size: 24),
          )
        : const Icon(M3EIcons.update, size: 18);

    return SizedBox(
      width: double.infinity,
      child: M3EButton.icon(
        style: M3EButtonStyle.filled,
        enabled: !checking,
        icon: icon,
        label: Text(label),
        onPressed: checking ? null : primaryAction,
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.update, required this.version});

  final AppUpdateState update;
  final AppVersion version;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final tone = SettingsPalette.of(context).about;
    final style = theme.typography.baseline.bodySmall.copyWith(
      color: tone.supporting,
    );

    final (Widget icon, String text, Color? color) = switch (update.phase) {
      AppUpdatePhase.idle => (
        Icon(M3EIcons.update, size: 15, color: tone.supporting),
        l10n.updateCheckSupport,
        null,
      ),
      AppUpdatePhase.checking => (
        Icon(M3EIcons.update, size: 15, color: tone.supporting),
        l10n.updateChecking,
        null,
      ),
      AppUpdatePhase.upToDate => (
        Icon(M3EIcons.check_circle_outline, size: 15, color: scheme.primary),
        l10n.updateUpToDate(version.version),
        null,
      ),
      AppUpdatePhase.available => (
        Icon(M3EIcons.download_outlined, size: 15, color: scheme.primary),
        l10n.updateAvailableDownload(update.release?.version ?? ''),
        null,
      ),
      AppUpdatePhase.failed => (
        Icon(M3EIcons.error_outline, size: 15, color: scheme.error),
        l10n.updateCheckFailed,
        scheme.error,
      ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 15, height: 18, child: Center(child: icon)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: color == null ? style : style.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
