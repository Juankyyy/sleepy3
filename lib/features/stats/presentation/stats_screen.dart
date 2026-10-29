import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/time/clock_format.dart';
import '../../../core/time/local_day_builder.dart';
import '../../../core/widgets/empty_state.dart';
import '../../health/application/sleep_data_source_controller.dart';
import '../../health/domain/sleep_data_source.dart';
import '../../sleep_tracking/application/sleep_tracking_controller.dart';
import '../../sleep_tracking/domain/sleep_history.dart';
import '../../sleep_tracking/domain/sleep_session.dart';
import '../../sleep_tracking/presentation/widgets/sleep_history_status.dart';
import 'widgets/sleep_history_list.dart';
import 'widgets/stats_range_selector.dart';
import 'widgets/stats_summary_card.dart';

/// The Stats destination: a range summary and the full session history.
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  SleepHistoryRange _range = SleepHistoryRange.sevenDays;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sleepTrackingControllerProvider);
    final controller = ref.read(sleepTrackingControllerProvider.notifier);
    final source = ref.watch(sleepDataSourceProvider);
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final margin = MediaQuery.sizeOf(context).width >= 600 ? 24.0 : 16.0;

    if (state.historyStatus == SleepHistoryStatus.initial ||
        state.historyStatus == SleepHistoryStatus.loading) {
      return _StatusLayout(
        margin: margin,
        openSession: state.openSession,
        child: const SleepHistoryLoadingCard(),
      );
    }

    if (state.historyStatus == SleepHistoryStatus.error) {
      return _StatusLayout(
        margin: margin,
        openSession: state.openSession,
        child: SleepHistoryErrorCard(
          onRetry: () => unawaited(controller.reloadHistory()),
        ),
      );
    }

    if (state.closedSessions.isEmpty) {
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(margin, 16, margin, 0),
            child: _StatsHeader(openSession: state.openSession),
          ),
          Expanded(
            child: Sleepy3EmptyState(
              icon: M3EIcons.insights_rounded,
              headline: source == SleepDataSource.healthConnect
                  ? 'No sleep history in Google Health'
                  : 'No sleep history yet',
              supportingText: source == SleepDataSource.healthConnect
                  ? 'Sleep sessions in Health Connect will appear here.'
                  : state.isSleeping
                  ? 'Your first night will appear here when you wake up.'
                  : 'Your nights will appear here after you wake up.',
            ),
          ),
        ],
      );
    }

    final clock = ref.watch(sleepClockProvider);

    return LocalDayBuilder(
      clock: clock,
      builder: (context, today) {
        final history = buildSleepHistory(
          now: today,
          sessions: state.closedSessions,
          range: _range,
        );
        // Only offer the shortcut when there is something older to show. A
        // range can be empty because every session is in the future (clock
        // skew); All would be empty too, so no button.
        final allHistory = !history.hasData && _range != SleepHistoryRange.all
            ? buildSleepHistory(
                now: today,
                sessions: state.closedSessions,
                range: SleepHistoryRange.all,
              )
            : null;
        final showAll = allHistory?.hasData ?? false;

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(margin, 16, margin, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StatsHeader(openSession: state.openSession),
                    const SizedBox(height: 24),
                    StatsRangeSelector(
                      selected: _range,
                      onChanged: (range) {
                        setState(() => _range = range);
                      },
                    ),
                    const SizedBox(height: 24),
                    StatsSummaryCard(
                      history: history,
                      onShowAll: showAll
                          ? () {
                              setState(() {
                                _range = SleepHistoryRange.all;
                              });
                            }
                          : null,
                    ),
                    if (history.hasData) ...[
                      const SizedBox(height: 24),
                      Semantics(
                        header: true,
                        child: Text(
                          'History',
                          style: theme.typography.emphasized.titleMedium
                              .copyWith(color: scheme.onSurface),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (history.hasData)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(margin, 8, margin, 0),
                sliver: SleepHistoryList(
                  history: history,
                  today: today,
                  use24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }
}

/// Screen title and, while a session is open, a short explanation of why that
/// night is not in the closed-session summary yet.
class _StatsHeader extends StatelessWidget {
  const _StatsHeader({required this.openSession});

  final SleepSession? openSession;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final open = openSession;
    final supporting = open == null
        ? 'Your sleep, night by night.'
        : 'Sleeping since '
              '${formatSessionTime(open.startedAt, use24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context))}'
              ' · it will appear when you wake.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Stats',
            style: theme.typography.emphasized.headlineMedium.copyWith(
              color: scheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          supporting,
          style: theme.typography.baseline.bodyMedium.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Header plus a centered loading or error card.
class _StatusLayout extends StatelessWidget {
  const _StatusLayout({
    required this.margin,
    required this.openSession,
    required this.child,
  });

  final double margin;
  final SleepSession? openSession;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(margin, 16, margin, 0),
          child: _StatsHeader(openSession: openSession),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(margin, 24, margin, 24),
            child: Center(child: child),
          ),
        ),
      ],
    );
  }
}
