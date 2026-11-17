import 'dart:ui' show SemanticsRole;

import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../domain/app_release.dart';
import '../domain/update_prompt_action.dart';

/// The launch dialog for a newer release.
///
/// This is a basic dialog composed from the `M3EDialog` theme tokens because
/// the package's basic `M3EDialog` has no header close affordance. It keeps the
/// 28dp surface, 24dp padding and 1dp section dividers. The two actions are the
/// per-version opt-out and the download; they sit side by side on a wide
/// dialog and stack on a compact one, with the confirming action above the
/// dismissive one. The GitHub page is a content link under the release theme.
class UpdateAvailableDialog extends StatelessWidget {
  const UpdateAvailableDialog({super.key, required this.release});

  final AppRelease release;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final dialogTheme = theme.dialogTheme;
    final appearance = dialogTheme.appearance;
    final l10n = context.l10n;
    final versionLine = 'Sleepy3 ${release.version}';
    final themeName = release.displayName;
    final subtitle = themeName == versionLine
        ? versionLine
        : '$versionLine · $themeName';

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      role: SemanticsRole.alertDialog,
      label: l10n.updateDialogSemantic(release.version),
      child: Container(
        constraints: BoxConstraints(
          minWidth: dialogTheme.minWidth,
          maxWidth: dialogTheme.maxWidth,
        ),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: dialogTheme.containerColor(scheme),
          borderRadius: dialogTheme.borderRadius,
          boxShadow: M3EElevation.shadows(
            dialogTheme.elevation,
            shadowColor: scheme.shadow,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Header(title: l10n.updateDialogTitle, subtitle: subtitle),
                    _divider(dialogTheme, scheme),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        dialogTheme.padding.left,
                        16,
                        dialogTheme.padding.right,
                        16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.updateWhatsNew,
                            style: theme.typography.emphasized.titleSmall
                                .copyWith(color: scheme.onSurface),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            release.summary ?? l10n.updateSummaryFallback,
                            style: appearance.resolveSupporting(theme),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _divider(dialogTheme, scheme),
            Padding(
              padding: EdgeInsets.fromLTRB(
                dialogTheme.padding.left,
                12,
                dialogTheme.padding.right,
                16,
              ),
              child: _Actions(
                onDontRemind: () =>
                    Navigator.of(context)
                        .pop(UpdatePromptAction.dismissVersion),
                onDownload: () =>
                    Navigator.of(context).pop(UpdatePromptAction.download),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(M3EDialogTheme dialogTheme, M3EColorScheme scheme) {
    return M3EDivider(
      color: scheme.outlineVariant,
      thickness: dialogTheme.dividerThickness,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final dialogTheme = theme.dialogTheme;
    final appearance = dialogTheme.appearance;
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        dialogTheme.padding.left,
        dialogTheme.padding.top,
        12,
        16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: appearance.resolveHeadline(theme)),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.typography.baseline.bodyMedium.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                M3EButton.icon(
                  style: M3EButtonStyle.text,
                  size: M3EButtonSize.sm,
                  decoration: const M3EButtonDecoration(
                    padding: EdgeInsets.zero,
                    minimumSize: Size(0, 40),
                  ),
                  icon: const Icon(M3EIcons.open_in_new_outlined, size: 18),
                  label: Text(l10n.updateOpenGitHub),
                  onPressed: () =>
                      Navigator.of(context).pop(UpdatePromptAction.openRelease),
                ),
              ],
            ),
          ),
          M3EIconButton(
            icon: const Icon(M3EIcons.close),
            variant: M3EIconButtonVariant.standard,
            size: M3EIconButtonSize.md,
            tooltip: l10n.updateCloseTooltip,
            semanticLabel: l10n.updateCloseTooltip,
            onPressed: () =>
                Navigator.of(context).pop(UpdatePromptAction.snooze),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.onDontRemind, required this.onDownload});

  final VoidCallback onDontRemind;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = M3ETheme.of(context).colorScheme;
    final dontRemind = M3EButton(
      style: M3EButtonStyle.text,
      size: M3EButtonSize.sm,
      decoration: M3EButtonDecoration(
        foregroundColor: WidgetStatePropertyAll<Color?>(
          scheme.onSurfaceVariant,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 40),
      ),
      onPressed: onDontRemind,
      child: Text(l10n.updateDontRemind),
    );
    final download = M3EButton(
      style: M3EButtonStyle.filled,
      size: M3EButtonSize.sm,
      onPressed: onDownload,
      child: Text(l10n.updateDownload),
    );

    // This is the same primitive M3EDialogActions uses: a row when both fit,
    // and a trailing stack with the confirming action above the dismissive one
    // when they do not.
    return OverflowBar(
      spacing: 8,
      overflowSpacing: 4,
      alignment: MainAxisAlignment.end,
      overflowAlignment: OverflowBarAlignment.end,
      overflowDirection: VerticalDirection.up,
      children: [dontRemind, download],
    );
  }
}
