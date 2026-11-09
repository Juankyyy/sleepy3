import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/sleepy3_theme.dart';
import '../../../core/time/local_day_builder.dart';
import '../../../l10n/l10n.dart';
import '../../health/application/health_history_permission_controller.dart';
import '../../health/application/sleep_data_source_controller.dart';
import '../../health/domain/health_history_access.dart';
import '../../health/domain/sleep_data_source.dart';
import '../../health/presentation/health_history_banner.dart';
import '../../sleep_tracking/application/sleep_tracking_controller.dart';
import '../../sleep_tracking/domain/sleep_history.dart';
import '../../sleep_tracking/domain/sleep_insights.dart';
import '../../sleep_tracking/presentation/widgets/sleep_history_status.dart';
import '../application/stats_range_controller.dart';
import 'charts/chart_format.dart';
import 'charts/sleep_duration_chart.dart';
import 'charts/sleep_window_chart.dart';
import 'charts/weekday_chart.dart';
import 'widgets/stats_insights_card.dart';
import 'widgets/stats_metrics_card.dart';
import 'widgets/stats_range_selector.dart';

/// The top margin a full-height modal sheet leaves above itself.
///
/// From M3: bottom sheets keep a 72dp top margin on compact windows and 56dp on
/// windows wider than 640dp, so the sheet still reads as a layer over the
/// screen instead of a new page.
const _sheetTopMargin = 72.0;
const _sheetTopMarginWide = 56.0;

/// The side margin a wide sheet keeps. From M3.
const _sheetSideMarginWide = 56.0;

/// The maximum width of a bottom sheet. From M3.
const _sheetMaxWidth = 640.0;

/// The resting preview height of the advanced sheet.
///
/// M3 caps a modal sheet's initial position at 50 % of the screen. Sleepy3
/// opens the advanced dashboard at 70 % so the four metrics and the start of
/// the first chart are visible without covering almost the whole summary. This
/// is a Sleepy3 design decision, not a Material rule. The sheet can still be
/// dragged to full height or down to close.
const _sheetInitialSize = 0.70;

/// The close icon button size used to measure the pinned header.
///
/// `M3EIconButtonSize.md` maps to the 56dp `M3EButtonSize.md` container.
const _sheetCloseSize = 56.0;

/// Opens the advanced Stats dashboard as a draggable modal sheet.
///
/// The sheet starts at 70 % of the screen with the summary dimmed behind it.
/// Dragging the pinned header up expands it to full height (the M3 72dp top
/// margin); dragging down returns it to 70 %, and dragging below the threshold
/// closes it. The close button, the scrim and Android back dismiss it too.
/// Header and content share one [CustomScrollView] and one scroll controller,
/// so the header stays pinned and the whole dashboard scrolls below it.
Future<void> showAdvancedStatsSheet(BuildContext context) {
  final scheme = M3ETheme.of(context).colorScheme;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    // The DraggableScrollableSheet owns the drag; the route's own drag would
    // compete with it. The route still listens for the sheet reaching its
    // minimum extent and closes itself.
    enableDrag: false,
    isDismissible: true,
    backgroundColor: Colors.transparent,
    barrierColor: scheme.scrim.withValues(alpha: 0.32),
    builder: (context) => const AdvancedStatsSheet(),
  );
}

/// The advanced Stats dashboard inside its draggable sheet.
///
/// It reads the same [statsRangeProvider] as the summary, so changing the range
/// here updates both surfaces without duplicating the permission flow.
class AdvancedStatsSheet extends ConsumerWidget {
  const AdvancedStatsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final state = ref.watch(sleepTrackingControllerProvider);
    final source = ref.watch(sleepDataSourceProvider);
    final permission = ref.watch(healthHistoryPermissionProvider);
    final range = ref.watch(statsRangeProvider);
    final clock = ref.watch(sleepClockProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final wide = screenWidth > 640;
    final topMargin = wide ? _sheetTopMarginWide : _sheetTopMargin;
    final sideMargin = wide ? _sheetSideMarginWide : 0.0;
    final sheetWidth = wide
        ? math.min(screenWidth - sideMargin * 2, _sheetMaxWidth)
        : screenWidth;
    final contentMargin = screenWidth >= 600 ? 24.0 : 16.0;
    final maxSize = math.max(
      _sheetInitialSize,
      (screenHeight - topMargin) / screenHeight,
    );
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final historyLimited =
        source == SleepDataSource.healthConnect &&
        range.requiresFullHistory &&
        permission != HealthHistoryAccess.authorized;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: _sheetInitialSize,
      minChildSize: 0,
      maxChildSize: maxSize,
      snap: true,
      snapSizes: [_sheetInitialSize, maxSize],
      shouldCloseOnMinExtent: true,
      builder: (context, scrollController) {
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: sheetWidth,
            height: double.infinity,
            child: Material(
              key: const Key('advanced-stats-surface'),
              color: scheme.surfaceContainerLow,
              elevation: 1,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              clipBehavior: Clip.antiAlias,
              child: LocalDayBuilder(
                clock: clock,
                builder: (context, today) {
                  final insights = buildSleepInsights(
                    now: today,
                    sessions: state.closedSessions,
                    range: range,
                  );
                  final ready = state.historyStatus == SleepHistoryStatus.ready;
                  final l10n = context.l10n;
                  final title = l10n.advancedStatsTitle;
                  final support = _supportLabel(l10n, range, ready, insights);
                  final titleStyle = Sleepy3Theme.brandTitle(
                    theme.typography.emphasized.titleLarge,
                  );
                  final supportStyle = theme.typography.baseline.bodySmall;
                  final titleWidth = math.max(
                    0.0,
                    sheetWidth - contentMargin * 2 - _sheetCloseSize,
                  );
                  final headerExtent = _headerExtent(
                    context,
                    title: title,
                    support: support,
                    titleStyle: titleStyle,
                    supportStyle: supportStyle,
                    titleWidth: titleWidth,
                  );

                  return CustomScrollView(
                    key: const Key('advanced-stats-scroll'),
                    controller: scrollController,
                    slivers: [
                      SliverPersistentHeader(
                        key: const Key('advanced-stats-header'),
                        pinned: true,
                        delegate: _SheetHeaderDelegate(
                          extent: headerExtent,
                          title: title,
                          support: support,
                          margin: contentMargin,
                          titleStyle: titleStyle,
                          supportStyle: supportStyle,
                          onClose: () => Navigator.of(context).pop(),
                        ),
                      ),
                      if (state.historyStatus == SleepHistoryStatus.initial ||
                          state.historyStatus == SleepHistoryStatus.loading)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              contentMargin,
                              24,
                              contentMargin,
                              24 + bottomInset,
                            ),
                            child: const SleepHistoryLoadingCard(),
                          ),
                        )
                      else if (state.historyStatus == SleepHistoryStatus.error)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              contentMargin,
                              24,
                              contentMargin,
                              24 + bottomInset,
                            ),
                            child: SleepHistoryErrorCard(
                              onRetry: () {
                                unawaited(
                                  ref
                                      .read(
                                        sleepTrackingControllerProvider
                                            .notifier,
                                      )
                                      .reloadHistory(),
                                );
                              },
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            contentMargin,
                            16,
                            contentMargin,
                            24 + bottomInset,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                StatsRangeSelector(
                                  selected: range,
                                  onChanged: (value) {
                                    unawaited(
                                      ref
                                          .read(statsRangeProvider.notifier)
                                          .select(value),
                                    );
                                  },
                                ),
                                HealthHistoryBanner(visible: historyLimited),
                                // 16dp separates the filters from the first
                                // card.
                                const SizedBox(height: 16),
                                StatsMetricsCard(insights: insights),
                                const SizedBox(height: 8),
                                SleepDurationChart(
                                  insights: insights,
                                  historyLimited: historyLimited,
                                ),
                                const SizedBox(height: 8),
                                SleepWindowChart(
                                  insights: insights,
                                  historyLimited: historyLimited,
                                ),
                                const SizedBox(height: 8),
                                WeekdayChart(
                                  insights: insights,
                                  historyLimited: historyLimited,
                                ),
                                const SizedBox(height: 8),
                                StatsInsightsCard(insights: insights),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  String _supportLabel(
    AppLocalizations l10n,
    SleepHistoryRange range,
    bool ready,
    SleepInsights insights,
  ) {
    final rangeLabel = chartRangeLabel(l10n, range);
    if (!ready || !insights.hasData) return rangeLabel;
    return '$rangeLabel · ${l10n.metricNights(insights.recordedDays)}';
  }

  double _headerExtent(
    BuildContext context, {
    required String title,
    required String support,
    required TextStyle titleStyle,
    required TextStyle supportStyle,
    required double titleWidth,
  }) {
    final textScaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);

    final titlePainter = TextPainter(
      text: TextSpan(text: title, style: titleStyle),
      textDirection: direction,
      textScaler: textScaler,
    )..layout(maxWidth: titleWidth);
    final supportPainter = TextPainter(
      text: TextSpan(text: support, style: supportStyle),
      textDirection: direction,
      textScaler: textScaler,
    )..layout(maxWidth: titleWidth);

    final rowHeight = math.max(
      titlePainter.height + 2 + supportPainter.height,
      _sheetCloseSize,
    );
    // Top padding, handle, gap, row and bottom padding.
    return 10 + 4 + 10 + rowHeight + 12;
  }
}

/// The pinned header delegate, so the handle, title and close stay visible
/// while the dashboard scrolls under them.
class _SheetHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _SheetHeaderDelegate({
    required this.extent,
    required this.title,
    required this.support,
    required this.margin,
    required this.titleStyle,
    required this.supportStyle,
    required this.onClose,
  });

  final double extent;
  final String title;
  final String support;
  final double margin;
  final TextStyle titleStyle;
  final TextStyle supportStyle;
  final VoidCallback onClose;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return SizedBox(
      key: const Key('advanced-stats-header-content'),
      height: extent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          border: Border(
            bottom: BorderSide(color: scheme.outlineVariant, width: 1),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(margin, 10, margin, 12),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.40),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // 10dp separates the handle from the title row.
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            style: titleStyle.copyWith(color: scheme.onSurface),
                          ),
                        ),
                        // 2dp keeps the range line attached to the title.
                        const SizedBox(height: 2),
                        Text(
                          support,
                          style: supportStyle.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  M3EIconButton(
                    icon: const Icon(M3EIcons.close),
                    variant: M3EIconButtonVariant.standard,
                    size: M3EIconButtonSize.md,
                    tooltip: l10n.close,
                    onPressed: onClose,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SheetHeaderDelegate oldDelegate) => true;
}
