import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../sleep_tracking/application/sleep_tracking_controller.dart';
import '../application/health_history_permission_controller.dart';
import '../application/sleep_data_source_controller.dart';
import '../domain/health_history_access.dart';
import '../domain/sleep_data_source.dart';

/// Explains the 30-day fallback and offers to ask for the full history.
///
/// Shown on Stats when Google Health is the selected source and the history
/// permission was denied. The update reloads the visible history, so a grant
/// made from here reveals older sessions immediately.
///
/// From M3: outlined card as the container and a text button for the single
/// low-emphasis action.
/// My design decisions (not in M3): using a card as an inline banner, the 12dp
/// icon/message gap, and the copy.
class HealthHistoryBanner extends ConsumerWidget {
  const HealthHistoryBanner({
    super.key,
    this.visible = true,
    this.padding = const EdgeInsets.only(top: 16),
  });

  /// Lets the caller hide the banner outside the context where it applies.
  /// A hidden banner takes no space.
  final bool visible;

  /// Surrounding layout spacing.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!visible) return const SizedBox.shrink();
    if (ref.watch(sleepDataSourceProvider) != SleepDataSource.healthConnect) {
      return const SizedBox.shrink();
    }
    // Only a resolved denial means the list really stops at 30 days. The
    // unknown state is resolved while the history loads.
    if (ref.watch(healthHistoryPermissionProvider) !=
        HealthHistoryAccess.denied) {
      return const SizedBox.shrink();
    }

    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: padding,
      child: M3ECard(
        variant: M3ECardVariant.outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(M3EIcons.history, color: scheme.onSurfaceVariant),
                // 12dp separates the status icon from its message.
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Only the last 30 days are available',
                    style: theme.typography.emphasized.titleSmall.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            // 8dp separates the message from its explanation.
            const SizedBox(height: 8),
            Text(
              'Allow full history in Google Health to see older sessions.',
              style: theme.typography.baseline.bodyMedium.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            // 8dp separates the explanation from its action.
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: M3EButton(
                style: M3EButtonStyle.text,
                size: M3EButtonSize.sm,
                onPressed: () => _allowFullHistory(context, ref),
                child: const Text('Allow full history'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _allowFullHistory(BuildContext context, WidgetRef ref) async {
    final granted = await ref
        .read(healthHistoryPermissionProvider.notifier)
        .ensureAuthorized();
    if (!context.mounted) return;

    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Google Health needs permission to read older sleep sessions.',
          ),
        ),
      );
      return;
    }

    await ref.read(sleepTrackingControllerProvider.notifier).reloadHistory();
  }
}
