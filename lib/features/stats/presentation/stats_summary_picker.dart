import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/sleepy3_theme.dart';
import '../../../core/time/local_day_builder.dart';
import '../../../l10n/l10n.dart';
import '../../sleep_tracking/application/sleep_tracking_controller.dart';
import '../../sleep_tracking/domain/sleep_insights.dart';
import '../application/stats_history_limited_provider.dart';
import '../application/stats_range_controller.dart';
import '../domain/stats_summary_option.dart';
import 'charts/chart_format.dart';
import 'charts/sleep_duration_chart.dart';
import 'charts/sleep_window_chart.dart';
import 'charts/weekday_chart.dart';
import 'stats_summary_labels.dart';
import 'widgets/stats_hero_card.dart';
import 'widgets/stats_insights_card.dart';
import 'widgets/stats_metrics_card.dart';
import 'widgets/stats_sheet_header.dart';

/// The M3 top margin for a full-height modal sheet on compact windows.
const _sheetTopMargin = 72.0;

/// The M3 top margin when the window is wider than 640dp.
const _sheetTopMarginWide = 56.0;

/// The M3 side margin when the window is wider than 640dp.
const _sheetSideMarginWide = 56.0;

/// The M3 maximum bottom-sheet width.
const _sheetMaxWidth = 640.0;

/// The height of a chart thumbnail inside the picker.
///
/// 240dp fits the duration chart without its hidden header, including the
/// legend. The real block is shown at full height in Stats; the picker clips
/// the longer window chart so the list stays navigable.
const _chartPreviewHeight = 240.0;

/// The height the picker rests at, as a fraction of the screen.
///
/// A short downward drag settles here instead of closing the picker.
const _restingSize = 0.80;

/// Opens the single-select summary-block picker and returns the chosen block.
///
/// The selection is applied by the caller. A tap on an option closes the sheet
/// immediately, so the Settings row and the Stats summary update in one step.
Future<StatsSummaryOption?> showStatsSummaryPicker(
  BuildContext context, {
  required StatsSummaryOption selected,
}) {
  final scheme = M3ETheme.of(context).colorScheme;
  return showModalBottomSheet<StatsSummaryOption>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    // The DraggableScrollableSheet owns the drag. The route must not compete
    // with it; the scrim and Android back still dismiss the sheet.
    enableDrag: false,
    isDismissible: true,
    backgroundColor: Colors.transparent,
    barrierColor: scheme.scrim.withValues(alpha: 0.32),
    builder: (context) => StatsSummaryPickerSheet(selected: selected),
  );
}

/// The M3 modal that chooses the single block above advanced Stats.
class StatsSummaryPickerSheet extends ConsumerWidget {
  const StatsSummaryPickerSheet({super.key, required this.selected});

  final StatsSummaryOption selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final state = ref.watch(sleepTrackingControllerProvider);
    final range = ref.watch(statsRangeProvider);
    final clock = ref.watch(sleepClockProvider);
    final historyLimited = ref.watch(statsHistoryLimitedProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final wide = screenWidth > 640;
    final topMargin = wide ? _sheetTopMarginWide : _sheetTopMargin;
    final sideMargin = wide ? _sheetSideMarginWide : 0.0;
    final sheetWidth = wide
        ? math.min(screenWidth - sideMargin * 2, _sheetMaxWidth)
        : screenWidth;
    final contentMargin = screenWidth >= 600 ? 24.0 : 16.0;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final maxSize = (screenHeight - topMargin) / screenHeight;
    final restingSize = math.min(_restingSize, maxSize);
    final snapSizes = <double>{0, restingSize, maxSize}.toList()..sort();
    final titleStyle = Sleepy3Theme.brandTitle(
      theme.typography.emphasized.titleLarge,
    );
    final supportStyle = theme.typography.baseline.bodySmall;
    final rangeStyle = theme.typography.baseline.labelSmall;
    final rangeLabel = historyLimited
        ? l10n.historyLast30DaysAvailable
        : chartRangeLabel(l10n, range);
    final currentBlock = statsSummaryOptionLabel(l10n, selected);
    final titleWidth = math.max(
      0.0,
      sheetWidth - contentMargin * 2 - statsSheetHeaderCloseSize,
    );

    return LocalDayBuilder(
      clock: clock,
      builder: (context, today) {
        final insights = buildSleepInsights(
          now: today,
          sessions: state.closedSessions,
          range: range,
        );
        final support = insights.hasData
            ? '$rangeLabel · ${l10n.metricNights(insights.recordedDays)}'
            : rangeLabel;
        final headerExtent = statsSheetHeaderExtent(
          context,
          title: l10n.statsSummary,
          support: support,
          titleStyle: titleStyle,
          supportStyle: supportStyle,
          titleWidth: titleWidth,
        );

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: restingSize,
          minChildSize: 0,
          maxChildSize: maxSize,
          snap: true,
          snapSizes: snapSizes,
          shouldCloseOnMinExtent: true,
          builder: (context, scrollController) {
            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: sheetWidth,
                height: double.infinity,
                child: Material(
                  key: const Key('stats-summary-picker-surface'),
                  color: scheme.surfaceContainerLow,
                  elevation: 1,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CustomScrollView(
                    key: const Key('stats-summary-picker-list'),
                    controller: scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: StatsSheetHeaderDelegate(
                          extent: headerExtent,
                          title: l10n.statsSummary,
                          support: support,
                          margin: contentMargin,
                          titleStyle: titleStyle,
                          supportStyle: supportStyle,
                          contentKey: const Key(
                            'stats-summary-picker-header-content',
                          ),
                          borderKey: const Key(
                            'stats-summary-picker-header-divider',
                          ),
                          handleKey: const Key('stats-summary-picker-handle'),
                          onClose: () => Navigator.of(context).pop(),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            contentMargin,
                            16,
                            contentMargin,
                            0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.statsSummarySupport,
                                style: supportStyle.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.statsSummaryCurrentBlock(currentBlock),
                                style: rangeStyle.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          contentMargin,
                          12,
                          contentMargin,
                          24 + bottomInset,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final option = StatsSummaryOption.values[index];
                            final isLast =
                                index == StatsSummaryOption.values.length - 1;
                            return Padding(
                              padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                              child: _StatsSummaryOptionCard(
                                option: option,
                                selected: option == selected,
                                insights: insights,
                                historyLimited: historyLimited,
                              ),
                            );
                          }, childCount: StatsSummaryOption.values.length),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// One real block preview inside the picker.
///
/// The outer filled card is the single-select target and owns the radio
/// semantics. The inner card is the same widget Stats uses, with its own title
/// hidden because the option header already names it.
class _StatsSummaryOptionCard extends StatelessWidget {
  const _StatsSummaryOptionCard({
    required this.option,
    required this.selected,
    required this.insights,
    required this.historyLimited,
  });

  final StatsSummaryOption option;
  final bool selected;
  final SleepInsights insights;
  final bool historyLimited;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final label = statsSummaryOptionLabel(l10n, option);

    return Semantics(
      container: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: label,
      onTap: () => Navigator.of(context).pop(option),
      child: ExcludeSemantics(
        child: M3ECard(
          variant: M3ECardVariant.filled,
          padding: const EdgeInsets.all(4),
          borderRadius: BorderRadius.circular(16),
          border: selected ? BorderSide(color: scheme.primary, width: 2) : null,
          onPressed: () => Navigator.of(context).pop(option),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? M3EIcons.radio_button_checked
                          : M3EIcons.radio_button_unchecked,
                      size: 20,
                      color: selected
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                    // 10dp separates the radio from the option name.
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: theme.typography.emphasized.titleSmall.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: IgnorePointer(
                  child: MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(disableAnimations: true),
                    child: _preview(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _preview() {
    return switch (option) {
      StatsSummaryOption.averageSleep => StatsHeroCard(
        insights: insights,
        showLabel: false,
      ),
      StatsSummaryOption.keyMetrics => StatsMetricsCard(insights: insights),
      StatsSummaryOption.sleepDuration => _chartPreview(
        SleepDurationChart(
          insights: insights,
          historyLimited: historyLimited,
          showHeader: false,
        ),
      ),
      StatsSummaryOption.sleepWindow => _chartPreview(
        SleepWindowChart(
          insights: insights,
          historyLimited: historyLimited,
          showHeader: false,
        ),
      ),
      StatsSummaryOption.weekday => _chartPreview(
        WeekdayChart(
          insights: insights,
          historyLimited: historyLimited,
          showHeader: false,
        ),
      ),
      StatsSummaryOption.keyData => StatsInsightsCard(
        insights: insights,
        compact: true,
        showTitle: false,
      ),
    };
  }

  Widget _chartPreview(Widget chart) {
    return SizedBox(
      height: _chartPreviewHeight,
      child: SingleChildScrollView(
        primary: false,
        physics: const NeverScrollableScrollPhysics(),
        child: chart,
      ),
    );
  }
}
