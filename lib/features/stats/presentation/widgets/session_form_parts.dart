import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../../sleep_tracking/domain/session_edit.dart';
import '../../../sleep_tracking/domain/session_night_context.dart';
import '../../../sleep_tracking/domain/sleep_goal.dart';
import '../session_edit_error_text.dart';
import 'sleep_goal_mark.dart';

/// The session's identity: duration, goal comparison and wake day.
///
/// From M3: a filled card with `primaryContainer` / `onPrimaryContainer` and
/// `headlineMedium` (28/36) for the duration. The accent container makes the
/// night the leading element; secondary information uses neutral surfaces.
/// Motion guides attention, and shape can carry progress by rotating.
///
/// My design decisions (not in M3): the 56 dp goal mark, the 20 dp card radius
/// shared with the history cards, the 16 dp padding and gap, and the wording
/// of the goal line. The turn is kept in the dialog details and off the
/// history list; there is no published M3 reduce-motion swap rule, so
/// following the Android setting is also a product decision.
class SessionHero extends StatefulWidget {
  const SessionHero({super.key, required this.duration, required this.endedAt});

  final Duration duration;
  final DateTime endedAt;

  @override
  State<SessionHero> createState() => _SessionHeroState();
}

class _SessionHeroState extends State<SessionHero>
    with SingleTickerProviderStateMixin {
  /// One continuous turn every eight seconds, clockwise.
  static const _turnPeriod = Duration(seconds: 8);

  late final AnimationController _turn;

  @override
  void initState() {
    super.initState();
    _turn = AnimationController(vsync: this, duration: _turnPeriod);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTurn();
  }

  @override
  void didUpdateWidget(covariant SessionHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTurn();
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  bool get _met => widget.duration >= dailySleepGoal;

  bool get _motionEnabled => !MediaQuery.disableAnimationsOf(context);

  /// Starts or stops the loop as the draft crosses the goal or the platform
  /// changes its animation preference. The controller is never reset while
  /// the tree is building; the mark is replaced anyway when the state changes.
  void _syncTurn() {
    if (_met && _motionEnabled) {
      if (!_turn.isAnimating) _turn.repeat();
    } else if (_turn.isAnimating) {
      _turn.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final motionEnabled = _motionEnabled;
    final spokenDate = DateFormat.yMMMMEEEEd(l10n.localeName)
        .format(widget.endedAt.toLocal());

    return Semantics(
      container: true,
      label: l10n.sessionHeroSpoken(
        l10n.formatSpokenSleepDuration(widget.duration),
        _spokenGoal(l10n, widget.duration),
        spokenDate,
      ),
      child: ExcludeSemantics(
        child: M3ECard(
          variant: M3ECardVariant.filled,
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SleepGoalMark(
                    duration: widget.duration,
                    size: 56,
                    strokeWidth: 5,
                    color: scheme.primary,
                    onColor: scheme.onPrimary,
                    trackColor: scheme.onPrimaryContainer.withValues(
                      alpha: 0.18,
                    ),
                    rotation: _met && motionEnabled ? _turn : null,
                    animateProgress: motionEnabled,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      l10n.formatSleepDuration(widget.duration),
                      style: theme.typography.emphasized.headlineMedium
                          .copyWith(
                            color: scheme.onPrimaryContainer,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _goalLabel(l10n, widget.duration),
                style: theme.typography.baseline.bodyMedium.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.wokeOn(
                  formatSessionEditorDate(widget.endedAt, l10n.localeName),
                ),
                style: theme.typography.baseline.bodySmall.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The goal line under the duration, for example `Goal met · 13m over the
/// 8h goal` or `58m short of the 8h goal`.
String _goalLabel(AppLocalizations l10n, Duration duration) {
  if (duration <= Duration.zero) return l10n.goalDefault;

  final difference = duration - dailySleepGoal;
  if (difference >= Duration.zero) {
    if (difference == Duration.zero) return l10n.goalMet;
    return l10n.goalOver(l10n.formatGoalDelta(difference));
  }
  return l10n.goalUnder(l10n.formatGoalDelta(-difference));
}

/// The same comparison for screen readers.
String _spokenGoal(AppLocalizations l10n, Duration duration) {
  if (duration <= Duration.zero) return l10n.spokenGoalDefault;

  final difference = duration - dailySleepGoal;
  if (difference == Duration.zero) return l10n.spokenGoalMet;
  if (difference > Duration.zero) {
    return l10n.spokenGoalOver(l10n.formatSpokenSleepDuration(difference));
  }
  return l10n.spokenGoalUnder(l10n.formatSpokenSleepDuration(-difference));
}

/// One labelled date and time pair.
///
/// The rows are static when [enabled] is false: no pickers and no trailing
/// calendar or clock icons.
class SessionTimeSection extends StatelessWidget {
  const SessionTimeSection({
    super.key,
    required this.title,
    required this.enabled,
    required this.date,
    required this.time,
    required this.onPickDate,
    required this.onPickTime,
  });

  final String title;

  /// Whether the rows open the date and time pickers.
  final bool enabled;

  final String date;
  final String time;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: theme.typography.emphasized.titleMedium.copyWith(
              color: scheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 8),
        M3EList(
          itemCount: 2,
          variant: M3ECardVariant.filled,
          outerRadius: 16,
          innerRadius: 4,
          gap: 2,
          semanticsLabel: l10n.sessionDateTimeSemantics(title),
          onTap: enabled
              ? (index) => index == 0 ? onPickDate() : onPickTime()
              : null,
          itemBuilder: (context, index) {
            final isDate = index == 0;
            return M3EListItem(
              headline: isDate ? date : time,
              trailing: enabled
                  ? Icon(
                      isDate
                          ? M3EIcons.event_outlined
                          : M3EIcons.schedule_outlined,
                    )
                  : null,
            );
          },
        ),
      ],
    );
  }
}

/// Inline note that the session also lives in Google Health.
class SessionHealthNotice extends StatelessWidget {
  const SessionHealthNotice({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(M3EIcons.cloud_sync_outlined, color: scheme.onSurfaceVariant),
        // 12dp separates the status icon from its message.
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: theme.typography.baseline.bodyMedium.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// Factual context for one session, without implying that it is editable.
///
/// From M3: outlined card, 12dp corners, 16dp padding, `titleMedium`
/// emphasized for the title, `bodyMedium` for the readings and `bodySmall` for
/// the split-night note.
/// My design decisions (not in M3): the 20dp leading icons and the 8dp gaps
/// between readings. The card never uses color alone: every reading spells out
/// `later`, `earlier` or `on your average`.
class SessionNightContextCard extends StatelessWidget {
  const SessionNightContextCard({super.key, required this.nightContext});

  final SessionNightContext nightContext;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final rank = nightContext.rank;

    return M3ECard(
      variant: M3ECardVariant.outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Row(
              children: [
                Icon(
                  M3EIcons.insights_outlined,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.nightContextTitle,
                    style: theme.typography.emphasized.titleMedium.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (nightContext.hasComparison) ...[
            _NightContextLine(
              icon: _durationIcon(nightContext.durationDelta!),
              text: _durationText(l10n),
            ),
            if (nightContext.bedtimeDelta case final delta?) ...[
              const SizedBox(height: 8),
              _NightContextLine(
                icon: M3EIcons.bedtime_outlined,
                text: _bedtimeText(l10n, delta),
              ),
            ],
            if (nightContext.wakeDelta case final delta?) ...[
              const SizedBox(height: 8),
              _NightContextLine(
                icon: M3EIcons.wb_sunny_outlined,
                text: _wakeText(l10n, delta),
              ),
            ],
          ] else
            Text(
              l10n.nightContextNotEnough,
              style: theme.typography.baseline.bodyMedium.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          if (rank != null) ...[
            const SizedBox(height: 8),
            _NightContextLine(
              icon: M3EIcons.emoji_events_outlined,
              text: rank == 1
                  ? l10n.nightContextLongest
                  : l10n.nightContextRanked(l10n.formatOrdinal(rank)),
            ),
          ],
          if (nightContext.isSplitNight) ...[
            const SizedBox(height: 8),
            _NightContextLine(
              icon: M3EIcons.groups_outlined,
              text: l10n.nightContextSplitNight(nightContext.nightSessionCount),
              supporting: true,
            ),
          ],
        ],
      ),
    );
  }

  String _durationText(AppLocalizations l10n) {
    final delta = nightContext.durationDelta!;
    if (delta == Duration.zero) {
      return l10n.nightContextDurationEven(nightContext.baselineNights);
    }
    return l10n.nightContextDurationDelta(
      l10n.formatSignedCompactDuration(delta),
      nightContext.baselineNights,
    );
  }

  String _bedtimeText(AppLocalizations l10n, Duration delta) {
    final formatted = l10n.formatGoalDelta(delta.abs());
    if (delta > Duration.zero) return l10n.nightContextBedtimeLater(formatted);
    if (delta < Duration.zero) {
      return l10n.nightContextBedtimeEarlier(formatted);
    }
    return l10n.nightContextBedtimeEven;
  }

  String _wakeText(AppLocalizations l10n, Duration delta) {
    final formatted = l10n.formatGoalDelta(delta.abs());
    if (delta > Duration.zero) return l10n.nightContextWakeLater(formatted);
    if (delta < Duration.zero) return l10n.nightContextWakeEarlier(formatted);
    return l10n.nightContextWakeEven;
  }

  IconData _durationIcon(Duration delta) {
    if (delta > Duration.zero) return M3EIcons.arrow_upward_rounded;
    if (delta < Duration.zero) return M3EIcons.arrow_downward_rounded;
    return M3EIcons.trending_flat;
  }
}

class _NightContextLine extends StatelessWidget {
  const _NightContextLine({
    required this.icon,
    required this.text,
    this.supporting = false,
  });

  final IconData icon;
  final String text;

  /// Supporting notes use `bodySmall` and `onSurfaceVariant`.
  final bool supporting;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final style =
        (supporting
                ? theme.typography.baseline.bodySmall
                : theme.typography.baseline.bodyMedium)
            .copyWith(
              color: supporting ? scheme.onSurfaceVariant : scheme.onSurface,
            );

    return Semantics(
      container: true,
      label: text,
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 20, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: style)),
          ],
        ),
      ),
    );
  }
}

/// The validation messages shown under the editor fields.
class SessionErrors extends StatelessWidget {
  const SessionErrors({super.key, required this.errors});

  final List<SessionEditError> errors;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final error in errors)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              l10n.sessionEditError(error),
              style: theme.typography.baseline.bodySmall.copyWith(
                color: scheme.error,
              ),
            ),
          ),
      ],
    );
  }
}

String formatSessionEditorDate(DateTime value, String localeName) =>
    DateFormat.yMMMEd(localeName).format(value.toLocal());

/// The compact date in a fact row.
///
/// The row's headline is a single line, so the year only appears when it is not
/// the current one; otherwise the weekday, month and day are enough and still
/// fit at 200 % text.
String formatSessionEditorDateRow(
  DateTime value,
  DateTime now,
  String localeName,
) {
  final local = value.toLocal();
  final format = local.year == now.toLocal().year
      ? DateFormat.MMMEd(localeName)
      : DateFormat.yMMMd(localeName);
  return format.format(local);
}

DateTime withSessionDate(DateTime value, DateTime date) =>
    DateTime(date.year, date.month, date.day, value.hour, value.minute);

DateTime withSessionTime(DateTime value, M3ETime time) =>
    DateTime(value.year, value.month, value.day, time.hour, time.minute);

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
