import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../../settings/domain/app_version.dart';
import '../../../settings/presentation/widgets/settings_action_row.dart';
import '../../../settings/presentation/widgets/settings_list.dart';
import '../../application/app_update_controller.dart';
import '../../domain/app_version_number.dart';

/// The `Check for updates` row in Settings > About.
class UpdateCheckRow extends ConsumerWidget {
  const UpdateCheckRow({super.key, required this.version});

  final AppVersion version;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final number = AppVersionNumber.tryParse(version.version);
    if (number == null) return const SizedBox.shrink();

    final state = ref.watch(appUpdateControllerProvider);
    final l10n = context.l10n;
    final scheme = M3ETheme.of(context).colorScheme;
    final releaseVersion = state.release?.version ?? number.toString();

    final (String supporting, Widget trailing) = switch (state.phase) {
      AppUpdatePhase.idle => (
        l10n.updateCheckSupport,
        Icon(M3EIcons.refresh, size: 24, color: scheme.onSurfaceVariant),
      ),
      AppUpdatePhase.checking => (
        l10n.updateChecking,
        const ExcludeSemantics(child: M3ELoadingIndicator(size: 24)),
      ),
      AppUpdatePhase.upToDate => (
        l10n.updateUpToDate(number.toString()),
        Icon(M3EIcons.check_circle_outlined, size: 24, color: scheme.primary),
      ),
      AppUpdatePhase.available => (
        l10n.updateAvailableDownload(releaseVersion),
        Icon(M3EIcons.download_outlined, size: 24, color: scheme.primary),
      ),
      AppUpdatePhase.failed => (
        l10n.updateCheckFailed,
        Icon(M3EIcons.refresh, size: 24, color: scheme.onSurfaceVariant),
      ),
    };

    return SettingsActionRow(
      key: const ValueKey('update-check-row'),
      showLeading: showSettingsLeadingIcons(context),
      leadingIcon: M3EIcons.update,
      headline: l10n.updateCheckTitle,
      supporting: supporting,
      trailing: trailing,
      onTap: () => unawaited(_handleTap(context, ref)),
    );
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    final opened = await ref
        .read(appUpdateControllerProvider.notifier)
        .handleRowTap();
    if (!context.mounted || opened) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.l10n.updateOpenFailed)));
  }
}
