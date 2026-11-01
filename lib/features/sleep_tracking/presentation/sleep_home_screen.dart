import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/time/clock_format.dart';
import '../../../core/time/day_phase.dart';
import '../../health/presentation/health_sync_banner.dart';
import '../application/sleep_tracking_controller.dart';
import '../domain/recent_sleep_summary.dart';
import '../domain/sleep_duration.dart';
import '../domain/sleep_session.dart';
import 'widgets/home_clock.dart';
import 'widgets/home_header.dart';
import 'widgets/live_clock.dart';
import 'widgets/recent_sleep_summary.dart';
import 'widgets/sleep_history_status.dart';
import 'widgets/track_buttons_row.dart';

/// The Home destination: brand, live clock, session line, actions and summary.
class SleepHomeScreen extends ConsumerWidget {
  const SleepHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sleepTrackingControllerProvider);
    final controller = ref.read(sleepTrackingControllerProvider.notifier);

    return Padding(
      // M3 compact layout margin.
      padding: const EdgeInsets.all(16),
      child: LiveClock(
        builder: (context, now) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeHeader(phase: dayPhaseFor(now)),
              const SizedBox(height: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            HomeClock(
                              now: now,
                              sessionLine: _sessionLine(context, state, now),
                            ),
                            // 32dp layout spacer between the clock and the
                            // actions.
                            const SizedBox(height: 32),
                            TrackButtonsRow(
                              isSleeping: state.isSleeping,
                              onSleep: () => unawaited(controller.sleep()),
                              onWake: () => unawaited(
                                _wake(context, controller, state, now),
                              ),
                            ),
                            // 16dp between the actions and the summary.
                            const SizedBox(height: 16),
                            const HealthSyncBanner(),
                            _HistorySummary(
                              state: state,
                              now: now,
                              onRetry: () =>
                                  unawaited(controller.reloadHistory()),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Confirms an under-minimum sleep, then lets the controller state machine
  /// run. The controller still rules: it re-checks the clock when the user
  /// confirms, so a sleep that crossed the minimum while the dialog was open
  /// records normally, and it discards without a dialog when Wake reaches it
  /// through another path.
  Future<void> _wake(
    BuildContext context,
    SleepTrackingController controller,
    SleepTrackingState state,
    DateTime now,
  ) async {
    final open = state.openSession;
    if (open == null) return;

    if (now.difference(open.startedAt) < minimumRecordableSleep) {
      final confirmed = await _confirmShortSleepDiscard(context);
      if (confirmed != true) return; // Keep sleeping: nothing was recorded.
    }

    await controller.wake();
  }

  Future<bool?> _confirmShortSleepDiscard(BuildContext context) {
    final scheme = M3ETheme.of(context).colorScheme;
    return M3EDialog.show<bool>(
      context,
      dialog: M3EDialog(
        title: 'Sleep too short',
        content: const Text(
          'Sleeps shorter than 10 minutes are not recorded. Are you sure '
          'you want to discard this session?',
        ),
        actions: [
          M3EButton(
            style: M3EButtonStyle.text,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep sleeping'),
          ),
          M3EButton(
            style: M3EButtonStyle.text,
            onPressed: () => Navigator.pop(context, true),
            decoration: M3EButtonDecoration(
              foregroundColor: WidgetStatePropertyAll<Color?>(scheme.error),
            ),
            child: const Text('Discard session'),
          ),
        ],
      ),
    );
  }

  String _sessionLine(
    BuildContext context,
    SleepTrackingState state,
    DateTime now,
  ) {
    final use24HourFormat = MediaQuery.alwaysUse24HourFormatOf(context);

    final open = state.openSession;
    if (open != null) {
      final time = formatSessionTime(
        open.startedAt,
        use24HourFormat: use24HourFormat,
      );
      return 'Sleeping since $time';
    }

    final last = state.lastSession;
    if (last != null) {
      return 'Last session: ${formatSleepDuration(last.duration)}';
    }

    return switch (dayPhaseFor(now)) {
      DayPhase.day => 'No active session',
      DayPhase.night => 'Tap Sleep when you turn off the lights',
    };
  }
}

/// The three-day summary, or the loading/error state of the history.
class _HistorySummary extends StatelessWidget {
  const _HistorySummary({
    required this.state,
    required this.now,
    required this.onRetry,
  });

  final SleepTrackingState state;
  final DateTime now;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (state.historyStatus) {
      SleepHistoryStatus.initial ||
      SleepHistoryStatus.loading => const SleepHistoryLoadingCard(),
      SleepHistoryStatus.error => SleepHistoryErrorCard(onRetry: onRetry),
      SleepHistoryStatus.ready => RecentSleepSummaryCard(
        summary: buildRecentSleepSummary(
          now: now,
          sessions: state.closedSessions,
        ),
      ),
    };
  }
}
