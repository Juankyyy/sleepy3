import 'dart:async';
import 'dart:math' as math;

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
    final bottomInset = MediaQuery.paddingOf(context).bottom;

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
                      padding: EdgeInsets.only(bottom: bottomInset),
                      child: ConstrainedBox(
                        // Keep the content centered in the space above the
                        // bottom inset. Using the full viewport here would make
                        // the scroll always extend by `bottomInset`, even when
                        // everything fits, and Home would scroll for nothing.
                        constraints: BoxConstraints(
                          minHeight: math.max(
                            0,
                            constraints.maxHeight - bottomInset,
                          ),
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
                              onWake: () =>
                                  unawaited(_wake(context, ref, state, now)),
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

  /// Confirms or fixes an out-of-range sleep, then lets the controller state
  /// machine run. The controller still rules: it re-checks the clock when the
  /// user confirms, so a sleep that crossed a limit while a dialog was open is
  /// handled with the fresh times, and it discards without a dialog when Wake
  /// reaches it through another path.
  Future<void> _wake(
    BuildContext context,
    WidgetRef ref,
    SleepTrackingState state,
    DateTime now,
  ) async {
    final open = state.openSession;
    if (open == null) return;

    final controller = ref.read(sleepTrackingControllerProvider.notifier);
    final duration = now.difference(open.startedAt);

    if (duration < minimumRecordableSleep) {
      final confirmed = await _confirmShortSleepDiscard(context);
      if (confirmed != true) return; // Keep sleeping: nothing was recorded.
    } else if (duration >= maximumRecordableSleep) {
      if (!context.mounted) return;
      final action = await _resolveLongSleep(context);
      switch (action) {
        case null:
          return; // Keep sleeping: nothing was recorded.
        case _LongSleepAction.discard:
          break;
        case _LongSleepAction.editStart:
          if (!context.mounted) return;
          final fixed = await _fixOpenSessionStart(context, ref, open);
          if (!fixed) return;
      }
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

  /// Asks what to do with a sleep of [maximumRecordableSleep] or more.
  ///
  /// Dismissing the dialog keeps the session open, so there is no separate
  /// "keep sleeping" action: M3 dialogs take at most two.
  Future<_LongSleepAction?> _resolveLongSleep(BuildContext context) {
    final scheme = M3ETheme.of(context).colorScheme;
    return M3EDialog.show<_LongSleepAction>(
      context,
      dialog: M3EDialog(
        title: 'Sleep too long',
        content: const Text(
          'Sleeps longer than 24 hours are not recorded. Edit the start time '
          'to keep this session, or discard it.',
        ),
        actions: [
          M3EButton(
            style: M3EButtonStyle.text,
            onPressed: () => Navigator.pop(context, _LongSleepAction.discard),
            decoration: M3EButtonDecoration(
              foregroundColor: WidgetStatePropertyAll<Color?>(scheme.error),
            ),
            child: const Text('Discard session'),
          ),
          M3EButton(
            style: M3EButtonStyle.text,
            onPressed: () => Navigator.pop(context, _LongSleepAction.editStart),
            child: const Text('Edit start time'),
          ),
        ],
      ),
    );
  }

  /// Lets the user pick a new start for the open session.
  ///
  /// Returns true only when the controller saved the new start, so the caller
  /// can close the session right away. A rejected start shows its message and
  /// leaves the session open.
  Future<bool> _fixOpenSessionStart(
    BuildContext context,
    WidgetRef ref,
    SleepSession open,
  ) async {
    final now = ref.read(sleepClockProvider)();
    final date = await M3EDatePicker.show(
      context,
      initialDate: open.startedAt,
      firstDate: DateTime(1970),
      lastDate: _dateOnly(now),
      currentDate: now,
      helpText: 'Select sleep date',
    );
    if (date == null || !context.mounted) return false;

    final time = await M3ETimePicker.show(
      context,
      initialTime: M3ETime(
        hour: open.startedAt.hour,
        minute: open.startedAt.minute,
      ),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      helpText: 'Select sleep time',
    );
    if (time == null || !context.mounted) return false;

    final startedAt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final error = await ref
        .read(sleepTrackingControllerProvider.notifier)
        .updateOpenSessionStart(startedAt);
    if (error == null) return true;
    if (!context.mounted) return false;

    await M3EDialog.show<void>(
      context,
      dialog: M3EDialog(
        title: 'Start time not saved',
        content: Text(error.message),
        actions: [
          M3EButton(
            style: M3EButtonStyle.text,
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
    return false;
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

/// The choice made in the `Sleep too long` dialog.
enum _LongSleepAction { editStart, discard }

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
