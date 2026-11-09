import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/l10n.dart';

/// The Home/Stats card shown while the selected source is being read.
///
/// M3 has no history-status component; this uses the same outlined card as the
/// recent summary with an expressive loading indicator.
class SleepHistoryLoadingCard extends StatelessWidget {
  const SleepHistoryLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return M3ECard(
      variant: M3ECardVariant.outlined,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        // Home stretches this card to the summary height; the content stays
        // centered inside the fixed slot. Stats gives it loose constraints,
        // where this alignment has no effect.
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          M3ELoadingIndicator(
            size: 32,
            semanticLabel: l10n.loadingSleepHistorySemantic,
          ),
          // 8dp separates the indicator from its label.
          const SizedBox(height: 8),
          Text(
            l10n.loadingSleepHistory,
            textAlign: TextAlign.center,
            style: theme.typography.baseline.bodyMedium.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// The Home/Stats card shown when the selected source fails to load.
class SleepHistoryErrorCard extends StatelessWidget {
  const SleepHistoryErrorCard({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return M3ECard(
      variant: M3ECardVariant.outlined,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(M3EIcons.error_outline, color: scheme.onSurfaceVariant),
          // 8dp separates the icon from the headline.
          const SizedBox(height: 8),
          Text(
            l10n.historyLoadError,
            textAlign: TextAlign.center,
            style: theme.typography.emphasized.titleMedium.copyWith(
              color: scheme.onSurface,
            ),
          ),
          // 4dp between the headline and its supporting line.
          const SizedBox(height: 4),
          Text(
            l10n.historyLoadErrorSupport,
            textAlign: TextAlign.center,
            style: theme.typography.baseline.bodyMedium.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          // 8dp separates the copy from the action.
          const SizedBox(height: 8),
          M3EButton(
            style: M3EButtonStyle.text,
            size: M3EButtonSize.sm,
            onPressed: onRetry,
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}
