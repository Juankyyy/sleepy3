import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/time/clock_format.dart';
import '../../../core/time/day_phase.dart';
import '../../../l10n/l10n.dart';
import '../../health/presentation/health_sync_banner.dart';
import '../../stats/presentation/session_edit_error_text.dart';
import '../application/sleep_tracking_controller.dart';
import '../domain/recent_sleep_summary.dart';
import '../domain/sleep_session.dart';
import 'widgets/home_clock.dart';
import 'widgets/home_header.dart';
import 'widgets/live_clock.dart';
import 'widgets/recent_sleep_summary.dart';
import 'widgets/sleep_history_status.dart';
import 'widgets/track_action_button.dart';

/// The Home destination: brand, live clock, session line, action and summary.
class SleepHomeScreen extends ConsumerWidget {
  const SleepHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sleepTrackingControllerProvider);
    final controller = ref.read(sleepTrackingControllerProvider.notifier);
    final open = state.openSession;
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
                            // action.
                            const SizedBox(height: 32),
                            TrackActionButton(
                              isSleeping: state.isSleeping,
                              sleepDuration: open == null
                                  ? null
                                  : now.difference(open.startedAt),
                              onSleep: () => unawaited(controller.sleep()),
                              onWake: (onSaving) =>
                                  _wake(context, ref, state, now, onSaving),
                            ),
                            // 16dp between the action and the summary.
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

  /// Confirms or fixes an out-of-range sleep, then closes it.
  ///
  /// The controller still rules: it re-checks the clock when the user confirms,
  /// so a sleep that crossed a limit while a dialog was open is handled with
  /// the fresh times, and it discards without a dialog when Wake reaches it
  /// through another path. [onSaving] runs only when a write will happen, after
  /// the dialogs, so the slide never shows "Saving session" behind one. A null
  /// result means the user chose to keep sleeping.
  Future<SleepWakeOutcome?> _wake(
    BuildContext context,
    WidgetRef ref,
    SleepTrackingState state,
    DateTime now,
    VoidCallback onSaving,
  ) async {
    final open = state.openSession;
    if (open == null) return null;

    final controller = ref.read(sleepTrackingControllerProvider.notifier);
    final duration = now.difference(open.startedAt);
    var discard = false;

    if (duration < minimumRecordableSleep) {
      final confirmed = await _confirmShortSleepDiscard(context);
      if (confirmed != true) {
        return null; // Keep sleeping: nothing was recorded.
      }
      discard = true;
    } else if (duration >= maximumRecordableSleep) {
      if (!context.mounted) return null;
      final action = await _resolveLongSleep(context);
      switch (action) {
        case null:
          return null; // Keep sleeping: nothing was recorded.
        case _LongSleepAction.discard:
          discard = true;
        case _LongSleepAction.editStart:
          if (!context.mounted) return null;
          final fixed = await _fixOpenSessionStart(context, ref, open);
          if (!fixed) return null;
      }
    }

    if (!context.mounted) return null;
    if (!discard) onSaving();
    return controller.wake();
  }

  Future<bool?> _confirmShortSleepDiscard(BuildContext context) {
    final scheme = M3ETheme.of(context).colorScheme;
    final l10n = context.l10n;
    return M3EDialog.show<bool>(
      context,
      dialog: M3EDialog(
        title: l10n.sleepTooShortTitle,
        content: Text(l10n.sleepTooShortBody),
        actions: [
          M3EButton(
            style: M3EButtonStyle.text,
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.keepSleeping),
          ),
          M3EButton(
            style: M3EButtonStyle.text,
            onPressed: () => Navigator.pop(context, true),
            decoration: M3EButtonDecoration(
              foregroundColor: WidgetStatePropertyAll<Color?>(scheme.error),
            ),
            child: Text(l10n.discardSession),
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
    final l10n = context.l10n;
    return M3EDialog.show<_LongSleepAction>(
      context,
      dialog: M3EDialog(
        title: l10n.sleepTooLongTitle,
        content: Text(l10n.sleepTooLongBody),
        actions: [
          M3EButton(
            style: M3EButtonStyle.text,
            onPressed: () => Navigator.pop(context, _LongSleepAction.discard),
            decoration: M3EButtonDecoration(
              foregroundColor: WidgetStatePropertyAll<Color?>(scheme.error),
            ),
            child: Text(l10n.discardSession),
          ),
          M3EButton(
            style: M3EButtonStyle.text,
            onPressed: () => Navigator.pop(context, _LongSleepAction.editStart),
            child: Text(l10n.editStartTime),
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
      helpText: context.l10n.selectSleepDate,
    );
    if (date == null || !context.mounted) return false;

    final time = await M3ETimePicker.show(
      context,
      initialTime: M3ETime(
        hour: open.startedAt.hour,
        minute: open.startedAt.minute,
      ),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      helpText: context.l10n.selectSleepTime,
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

    final l10n = context.l10n;
    await M3EDialog.show<void>(
      context,
      dialog: M3EDialog(
        title: l10n.startTimeNotSaved,
        content: Text(l10n.sessionEditError(error)),
        actions: [
          M3EButton(
            style: M3EButtonStyle.text,
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
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
    final l10n = context.l10n;
    final use24HourFormat = MediaQuery.alwaysUse24HourFormatOf(context);

    final open = state.openSession;
    if (open != null) {
      final time = formatSessionTime(
        open.startedAt,
        use24HourFormat: use24HourFormat,
        localeName: l10n.localeName,
      );
      return l10n.sleepingSince(time);
    }

    final last = state.lastSession;
    if (last != null) {
      return l10n.lastSession(l10n.formatSleepDuration(last.duration));
    }

    return switch (dayPhaseFor(now)) {
      DayPhase.day => l10n.noActiveSession,
      DayPhase.night => l10n.tapSleepAtNight,
    };
  }
}

/// The three-day summary, or the loading state of the history.
///
/// The card keeps one height for the whole load: an invisible reference with
/// the longest duration copy reserves the slot, and the visible card fills it.
/// Home centers its content vertically, so a shorter loading card would move
/// the clock and the action every time the history was read.
class _HistorySummary extends StatelessWidget {
  const _HistorySummary({
    required this.state,
    required this.now,
    required this.onRetry,
  });

  /// Same layout as the real summary, with the longest duration copy, so the
  /// slot is never shorter than the card it will show at the current width and
  /// text scale.
  static final _heightReference = RecentSleepSummary(
    days: [
      for (var offset = 0; offset < recentSleepSummaryDayCount; offset++)
        SleepDaySummary(
          date: DateTime(2000, 1, 1 + offset),
          duration: const Duration(hours: 23, minutes: 59),
        ),
    ],
    average: const Duration(hours: 23, minutes: 59),
  );

  final SleepTrackingState state;
  final DateTime now;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final Widget? content = switch (state.historyStatus) {
      SleepHistoryStatus.initial ||
      SleepHistoryStatus.loading => const SleepHistoryLoadingCard(),
      SleepHistoryStatus.ready => RecentSleepSummaryCard(
        key: const Key('home-history-summary'),
        summary: buildRecentSleepSummary(
          now: now,
          sessions: state.closedSessions,
        ),
      ),
      SleepHistoryStatus.error => null,
    };

    if (content == null) {
      return SleepHistoryErrorCard(onRetry: onRetry);
    }

    return _StableHistorySlot(
      reference: RecentSleepSummaryCard(
        key: const Key('home-history-sizer'),
        summary: _heightReference,
      ),
      child: content,
    );
  }
}

/// Reserves the height of [reference] and stretches [child] to fill it.
///
/// Both cards are laid out at the same width; the reference stays invisible and
/// out of the semantics tree, so it only contributes its size.
class _StableHistorySlot extends StatelessWidget {
  const _StableHistorySlot({required this.reference, required this.child});

  final Widget reference;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Visibility(
          visible: false,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: reference,
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

/// The choice made in the `Sleep too long` dialog.
enum _LongSleepAction { editStart, discard }

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
