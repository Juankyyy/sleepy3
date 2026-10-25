import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../application/sleep_tracking_controller.dart';
import '../domain/sleep_duration.dart';
import 'widgets/track_buttons_row.dart';

/// The Home destination: brand, session line and the two tracking actions.
class SleepHomeScreen extends ConsumerWidget {
  const SleepHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sleepTrackingControllerProvider);
    final controller = ref.read(sleepTrackingControllerProvider.notifier);
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Semantics(
            header: true,
            child: Text(
              'Sleepy3',
              textAlign: TextAlign.center,
              style: theme.typography.emphasized.headlineLarge.copyWith(
                color: scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _sessionLine(context, state),
            textAlign: TextAlign.center,
            style: theme.typography.baseline.bodyMedium.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          TrackButtonsRow(
            isSleeping: state.isSleeping,
            onSleep: () => unawaited(controller.sleep()),
            onWake: () => unawaited(controller.wake()),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _sessionLine(BuildContext context, SleepTrackingState state) {
    final localizations = MaterialLocalizations.of(context);
    final open = state.openSession;

    if (open != null) {
      final time = localizations.formatTimeOfDay(
        TimeOfDay.fromDateTime(open.startedAt),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      );
      return 'Sleeping since $time';
    }

    final last = state.lastSession;
    if (last != null) {
      return 'Last session: ${formatSleepDuration(last.duration)}';
    }

    return 'Tap Sleep to start';
  }
}
