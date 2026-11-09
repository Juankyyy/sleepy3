import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/sleepy3_theme.dart';
import '../../../core/time/clock_format.dart';
import '../../../core/time/local_day_builder.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../l10n/l10n.dart';
import '../../health/application/current_app_package_provider.dart';
import '../../health/application/health_history_permission_controller.dart';
import '../../health/application/health_sync_controller.dart';
import '../../health/application/sleep_data_source_controller.dart';
import '../../health/domain/health_history_access.dart';
import '../../health/domain/sleep_data_source.dart';
import '../../health/domain/sleepy3_health_source.dart';
import '../../health/presentation/health_history_banner.dart';
import '../../health/presentation/health_sync_banner.dart';
import '../../sleep_tracking/application/sleep_session_edit_service.dart';
import '../../sleep_tracking/application/sleep_tracking_controller.dart';
import '../../sleep_tracking/domain/session_edit.dart';
import '../../sleep_tracking/domain/sleep_history.dart';
import '../../sleep_tracking/domain/sleep_insights.dart';
import '../../sleep_tracking/domain/sleep_session.dart';
import '../../sleep_tracking/presentation/widgets/sleep_history_status.dart';
import 'charts/sleep_duration_chart.dart';
import 'charts/sleep_window_chart.dart';
import 'charts/weekday_chart.dart';
import 'widgets/session_editor.dart';
import 'widgets/sleep_history_list.dart';
import 'widgets/stats_hero_card.dart';
import 'widgets/stats_insights_card.dart';
import 'widgets/stats_metrics_card.dart';
import 'widgets/stats_range_selector.dart';

/// The Stats destination: a range summary and the full session history.
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen>
    with SingleTickerProviderStateMixin {
  /// The contained M3 loader at its default size: 48 dp container and 38 dp
  /// active shape.
  static const _loaderSize = 48.0;

  /// Hidden position above the scroll view, so the 48 dp loader clears the top
  /// edge before it starts descending.
  static const _loaderBaseTop = -56.0;

  /// How far the loader travels per unit of pull, and how much of the finger
  /// movement becomes pull.
  static const _pullTravel = 1.2;
  static const _pullFactor = 0.6;
  static const _maxPull = 160.0;

  /// The pull at which releasing starts the refresh.
  static const _armedPull = 80.0;

  /// Where the loader rests while refreshing. It stays near where the user
  /// released it, clamped so it never sits on the very top edge or too low.
  static const _lockMinTop = 56.0;
  static const _lockMaxTop = 140.0;

  static const _minLoaderScale = 0.6;
  static const _maxLoaderScale = 1.05;
  static const _loaderScalePull = 140.0;
  static const _loaderOpacityPull = 40.0;

  static const _settleDuration = Duration(milliseconds: 320);
  static const _settleCurve = Curves.easeOutCubic;

  SleepHistoryRange _range = SleepHistoryRange.week;

  late final AnimationController _pullController;
  bool _dragging = false;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _pullController = AnimationController(
      vsync: this,
      lowerBound: 0,
      upperBound: _maxPull,
    );
  }

  @override
  void dispose() {
    _pullController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sleepTrackingControllerProvider);
    final controller = ref.read(sleepTrackingControllerProvider.notifier);
    final source = ref.watch(sleepDataSourceProvider);
    final l10n = context.l10n;
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final margin = MediaQuery.sizeOf(context).width >= 600 ? 24.0 : 16.0;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

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

    final clock = ref.watch(sleepClockProvider);

    return LocalDayBuilder(
      clock: clock,
      builder: (context, today) {
        final history = buildSleepHistory(
          now: today,
          sessions: state.closedSessions,
          range: _range,
        );
        final insights = buildSleepInsights(
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

        final isEmpty = state.closedSessions.isEmpty;

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Semantics(
                customSemanticsActions: {
                  CustomSemanticsAction(label: l10n.refreshSleepHistory):
                      _refreshFromSemantics,
                },
                child: NotificationListener<ScrollNotification>(
                  onNotification: _handleScrollNotification,
                  child: NotificationListener<OverscrollIndicatorNotification>(
                    onNotification: _handleIndicatorNotification,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(margin, 16, margin, 0),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _StatsHeader(openSession: state.openSession),
                                if (isEmpty)
                                  HealthHistoryBanner(
                                    visible:
                                        source == SleepDataSource.healthConnect,
                                  )
                                else ...[
                                  const SizedBox(height: 24),
                                  StatsRangeSelector(
                                    selected: _range,
                                    onChanged: (range) {
                                      unawaited(_selectRange(range));
                                    },
                                  ),
                                  HealthHistoryBanner(
                                    visible:
                                        source ==
                                            SleepDataSource.healthConnect &&
                                        _range.requiresFullHistory,
                                  ),
                                  const SizedBox(height: 24),
                                  StatsHeroCard(
                                    insights: insights,
                                    onShowAll: showAll
                                        ? () {
                                            unawaited(
                                              _selectRange(
                                                SleepHistoryRange.all,
                                              ),
                                            );
                                          }
                                        : null,
                                  ),
                                  const SizedBox(height: 8),
                                  StatsMetricsCard(insights: insights),
                                  const SizedBox(height: 8),
                                  SleepDurationChart(insights: insights),
                                  const SizedBox(height: 8),
                                  SleepWindowChart(insights: insights),
                                  const SizedBox(height: 8),
                                  WeekdayChart(insights: insights),
                                  const SizedBox(height: 8),
                                  StatsInsightsCard(insights: insights),
                                  if (history.hasData) ...[
                                    const SizedBox(height: 24),
                                    Semantics(
                                      header: true,
                                      child: Text(
                                        l10n.history,
                                        style: theme
                                            .typography
                                            .emphasized
                                            .titleMedium
                                            .copyWith(color: scheme.onSurface),
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Padding(
                              padding: EdgeInsets.only(bottom: bottomInset),
                              child: Sleepy3EmptyState(
                                scrollable: false,
                                icon: M3EIcons.analytics_rounded,
                                headline:
                                    source == SleepDataSource.healthConnect
                                    ? l10n.noSleepHistoryHealth
                                    : l10n.noSleepHistory,
                                supportingText:
                                    source == SleepDataSource.healthConnect
                                    ? l10n.noSleepHistoryHealthSupport
                                    : state.isSleeping
                                    ? l10n.noSleepHistorySleepingSupport
                                    : l10n.noSleepHistorySupport,
                              ),
                            ),
                          )
                        else ...[
                          if (history.hasData)
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                margin,
                                8,
                                margin,
                                0,
                              ),
                              sliver: SleepHistoryList(
                                history: history,
                                today: today,
                                use24HourFormat:
                                    MediaQuery.alwaysUse24HourFormatOf(context),
                                source: source,
                                compact: _range != SleepHistoryRange.week,
                                onEdit: (session) =>
                                    unawaited(_openEditor(session)),
                              ),
                            ),
                          SliverToBoxAdapter(
                            child: SizedBox(height: 24 + bottomInset),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _buildLoaderOverlay(),
          ],
        );
      },
    );
  }

  SessionEditAccess _accessFor(SleepSession session, SleepDataSource source) {
    return sessionEditAccess(
      session,
      healthConnectSource: source == SleepDataSource.healthConnect,
      isOwnHealthRecord: isHealthRecordOwnedBy(
        session.sourceId,
        ref.read(currentAppPackageProvider),
      ),
    );
  }

  /// Opens the editor and reports only outcomes the user must know about.
  ///
  /// Read-only sessions still open, but the editor locks its fields and
  /// explains why; it never returns a result.
  Future<void> _openEditor(SleepSession session) async {
    final source = ref.read(sleepDataSourceProvider);
    final access = _accessFor(session, source);

    final result = await showSessionEditor(
      context,
      session: session,
      source: source,
      access: access,
      range: _range,
    );
    if (!mounted || result == null) return;

    final l10n = context.l10n;
    final message = switch (result.status) {
      SleepSessionEditStatus.saved => null,
      SleepSessionEditStatus.savedPendingSync => l10n.sessionSavedPendingSync,
      SleepSessionEditStatus.deleted => l10n.sessionDeleted,
      SleepSessionEditStatus.permissionNeeded =>
        result.hasLocalChange ? l10n.sessionSavedLocallyPermission : null,
      SleepSessionEditStatus.failed => null,
    };
    if (message != null) {
      M3ESnackbar.show(context, message: message);
    }
  }

  /// Applies a range, asking for the full history first when the range is
  /// wider than the 30-day fallback in Google Health mode.
  ///
  /// A denial still selects the range: the list keeps the last 30 days already
  /// loaded and the banner explains the limit.
  Future<void> _selectRange(SleepHistoryRange range) async {
    if (range == _range) return;

    final needsHistory =
        range.requiresFullHistory &&
        ref.read(sleepDataSourceProvider) == SleepDataSource.healthConnect &&
        ref.read(healthHistoryPermissionProvider) !=
            HealthHistoryAccess.authorized;

    if (needsHistory) {
      final granted = await ref
          .read(healthHistoryPermissionProvider.notifier)
          .ensureAuthorized();
      if (!mounted) return;

      if (granted) {
        await ref
            .read(sleepTrackingControllerProvider.notifier)
            .reloadHistory();
        if (!mounted) return;
      }
    }

    if (!mounted) return;
    setState(() => _range = range);
  }

  /// Builds the floating M3 loader above the scroll view.
  ///
  /// The list never moves. The loader starts above the top edge and follows the
  /// pull until it reaches the lock range, then stays there while the refresh
  /// runs. The loader is ignored by hit testing so the list below can still be
  /// scrolled.
  Widget _buildLoaderOverlay() {
    final scheme = M3ETheme.of(context).colorScheme;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: 1,
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _pullController,
            builder: (context, child) {
              final pull = _pullController.value;
              if (pull <= 0 && !_refreshing) return const SizedBox.shrink();

              final top = _loaderTopFor(pull);
              final scale = _refreshing ? 1.0 : _loaderScaleFor(pull);
              final opacity = _refreshing ? 1.0 : _loaderOpacityFor(pull);

              return Transform.translate(
                offset: Offset(0, top),
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    // M3's refresh indicator gives the contained loader an
                    // elevation so it separates from the content below.
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: scheme.shadow.withValues(alpha: 0.18),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: M3ELoadingIndicator(
                        size: _loaderSize,
                        variant: M3ELoadingIndicatorVariant.contained,
                        // Manual during the pull so the shape follows the
                        // finger; the component morphs on its own while
                        // refreshing.
                        rotationTurns: _refreshing
                            ? null
                            : (pull / _maxPull) * 0.5,
                        semanticLabel: context.l10n.refreshingSleepHistory,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_refreshing) return false;
    if (notification.metrics.axis != Axis.vertical ||
        notification.metrics.axisDirection != AxisDirection.down) {
      return false;
    }

    if (notification is ScrollStartNotification &&
        notification.dragDetails != null &&
        notification.metrics.extentBefore == 0) {
      _pullController.stop();
      _pullController.value = 0;
      _dragging = true;
      return false;
    }

    if (!_dragging) return false;

    if (notification is OverscrollNotification) {
      _pullController.value -= notification.overscroll * _pullFactor;
    } else if (notification is ScrollUpdateNotification) {
      _pullController.value -= (notification.scrollDelta ?? 0) * _pullFactor;
    } else if (notification is ScrollEndNotification) {
      _dragging = false;
      if (_pullController.value >= _armedPull) {
        unawaited(_beginRefresh());
      } else {
        unawaited(_settlePull(0));
      }
    }

    return false;
  }

  /// Suppresses the platform overscroll effect while the user is pulling.
  ///
  /// The screen must stay still; only the loader moves. Without this, Android's
  /// stretch/glow would move the list under the pull.
  bool _handleIndicatorNotification(
    OverscrollIndicatorNotification notification,
  ) {
    if (notification.depth != 0 || !notification.leading) return false;
    if (_dragging) {
      notification.disallowIndicator();
      return true;
    }
    return false;
  }

  double _loaderTopFor(double pull) => _loaderBaseTop + pull * _pullTravel;

  double _loaderScaleFor(double pull) {
    final progress = (pull / _loaderScalePull).clamp(0.0, 1.0).toDouble();
    return _minLoaderScale + (_maxLoaderScale - _minLoaderScale) * progress;
  }

  double _loaderOpacityFor(double pull) =>
      (pull / _loaderOpacityPull).clamp(0.0, 1.0).toDouble();

  Future<void> _settlePull(double target) async {
    await _pullController.animateTo(
      target,
      duration: _settleDuration,
      curve: _settleCurve,
    );
  }

  /// Non-gesture refresh for assistive technology.
  void _refreshFromSemantics() {
    if (_refreshing) return;
    _pullController.value = (_lockMinTop - _loaderBaseTop) / _pullTravel;
    unawaited(_beginRefresh());
  }

  /// Moves the loader to its resting position and syncs before re-reading.
  ///
  /// Uploads already pending for Health Connect are retried first. Local mode
  /// only retries updates of sessions that already have a Health Connect
  /// record; it never uploads a new local session from here.
  Future<void> _beginRefresh() async {
    if (!mounted || _refreshing) return;

    final currentTop = _loaderTopFor(_pullController.value);
    final lockTop = currentTop.clamp(_lockMinTop, _lockMaxTop).toDouble();
    final targetPull = (lockTop - _loaderBaseTop) / _pullTravel;

    setState(() => _refreshing = true);
    await _pullController.animateTo(
      targetPull,
      duration: _settleDuration,
      curve: _settleCurve,
    );
    if (!mounted) return;

    await ref.read(healthSyncControllerProvider.notifier).retryPending();
    if (!mounted) return;

    final refreshed = await ref
        .read(sleepTrackingControllerProvider.notifier)
        .refreshHistory();
    if (!mounted) return;

    setState(() => _refreshing = false);
    await _settlePull(0);
    if (!mounted) return;

    if (!refreshed) {
      M3ESnackbar.show(context, message: context.l10n.refreshFailed);
    }
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
    final l10n = context.l10n;
    final open = openSession;
    final supporting = open == null
        ? l10n.statsSupport
        : l10n.statsSupportingSleeping(
            formatSessionTime(
              open.startedAt,
              use24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
              localeName: l10n.localeName,
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.statsTitle,
            style: Sleepy3Theme.brandTitle(
              theme.typography.emphasized.headlineMedium,
            ).copyWith(color: scheme.onSurface),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          supporting,
          style: theme.typography.baseline.bodyMedium.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        // 24dp separates the header from the pending banner, matching the gap
        // used before the range selector.
        const HealthSyncBanner(padding: EdgeInsets.only(top: 24)),
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
            padding: EdgeInsets.fromLTRB(
              margin,
              24,
              margin,
              24 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Center(child: child),
          ),
        ),
      ],
    );
  }
}
