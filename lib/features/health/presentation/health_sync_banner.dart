import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../sleep_tracking/application/sleep_tracking_controller.dart';
import '../application/health_sync_controller.dart';
import '../application/sleep_data_source_controller.dart';
import '../domain/sleep_data_source.dart';

/// The pending-upload banner for Home and Stats.
///
/// It is only shown in Google Health mode when at least one finished local
/// session is still waiting to reach Health Connect.
///
/// From M3: outlined card as the container and a text button for the single
/// low-emphasis action.
/// My design decisions (not in M3): using a card as an inline banner, the 12dp
/// icon/message gap, and the count copy.
class HealthSyncBanner extends ConsumerWidget {
  const HealthSyncBanner({
    super.key,
    this.padding = const EdgeInsets.only(bottom: 16),
  });

  /// Surrounding layout spacing. Hidden banners take no space.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(sleepDataSourceProvider);
    if (source != SleepDataSource.healthConnect) {
      return const SizedBox.shrink();
    }

    final state = ref.watch(healthSyncControllerProvider);
    if (state.pendingCount == 0) return const SizedBox.shrink();

    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final count = state.pendingCount;

    return Padding(
      padding: padding,
      child: M3ECard(
        variant: M3ECardVariant.outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  M3EIcons.cloud_sync_outlined,
                  color: scheme.onSurfaceVariant,
                ),
                // 12dp separates the status icon from its message.
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    count == 1
                        ? '1 session waiting to sync'
                        : '$count sessions waiting to sync',
                    style: theme.typography.emphasized.titleSmall.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            // 8dp separates the message from its action.
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: M3EButton(
                style: M3EButtonStyle.text,
                size: M3EButtonSize.sm,
                enabled: !state.syncing,
                onPressed: state.syncing ? null : () => _retry(context, ref),
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _retry(BuildContext context, WidgetRef ref) async {
    final sync = ref.read(healthSyncControllerProvider.notifier);
    await sync.retryPending();
    if (!context.mounted) return;

    // Retrying is what makes the pending sessions appear in Health Connect,
    // so the visible history must be read again.
    await ref.read(sleepTrackingControllerProvider.notifier).reloadHistory();
  }
}
