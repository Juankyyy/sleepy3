import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../sleep_tracking/domain/session_edit.dart';
import '../../../sleep_tracking/domain/sleep_duration.dart';
import '../../../sleep_tracking/domain/sleep_goal.dart';
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
    final motionEnabled = _motionEnabled;
    final spokenDate = _spokenDate.format(widget.endedAt);

    return Semantics(
      container: true,
      label:
          '${formatSpokenSleepDuration(widget.duration)}, '
          '${_spokenGoal(widget.duration)}, woke $spokenDate',
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
                      formatSleepDuration(widget.duration),
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
                _goalLabel(widget.duration),
                style: theme.typography.baseline.bodyMedium.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Woke ${formatSessionEditorDate(widget.endedAt)}',
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
String _goalLabel(Duration duration) {
  if (duration <= Duration.zero) return 'Your 8h goal';

  final difference = duration - dailySleepGoal;
  if (difference >= Duration.zero) {
    if (difference == Duration.zero) return 'Goal met';
    return 'Goal met · ${_goalDelta(difference)} over the 8h goal';
  }
  return '${_goalDelta(-difference)} short of the 8h goal';
}

/// The same comparison for screen readers.
String _spokenGoal(Duration duration) {
  if (duration <= Duration.zero) return '8-hour goal';

  final difference = duration - dailySleepGoal;
  if (difference == Duration.zero) return 'goal met';
  if (difference > Duration.zero) {
    return 'goal met, ${formatSpokenSleepDuration(difference)} over the '
        '8-hour goal';
  }
  return '${formatSpokenSleepDuration(-difference)} short of the 8-hour goal';
}

/// A goal delta without a zero minute part: `13m`, `1h`, `1h 12m`.
String _goalDelta(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours == 0) return '${minutes}m';
  if (minutes == 0) return '${hours}h';
  return '${hours}h ${minutes}m';
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
          semanticsLabel: '$title date and time',
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

/// The validation messages shown under the editor fields.
class SessionErrors extends StatelessWidget {
  const SessionErrors({super.key, required this.errors});

  final List<SessionEditError> errors;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final error in errors)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              error.message,
              style: theme.typography.baseline.bodySmall.copyWith(
                color: scheme.error,
              ),
            ),
          ),
      ],
    );
  }
}

final _editorDate = DateFormat('EEE, MMM d, y', 'en_US');
final _editorDateNoYear = DateFormat('EEE, MMM d', 'en_US');
final _editorDateNoWeekday = DateFormat('MMM d, y', 'en_US');
final _spokenDate = DateFormat('EEEE, MMMM d, y', 'en_US');

String formatSessionEditorDate(DateTime value) =>
    _editorDate.format(value.toLocal());

/// The compact date in a fact row.
///
/// The row's headline is a single line, so the year only appears when it is not
/// the current one; otherwise the weekday, month and day are enough and still
/// fit at 200 % text.
String formatSessionEditorDateRow(DateTime value, DateTime now) {
  final local = value.toLocal();
  return local.year == now.toLocal().year
      ? _editorDateNoYear.format(local)
      : _editorDateNoWeekday.format(local);
}

DateTime withSessionDate(DateTime value, DateTime date) =>
    DateTime(date.year, date.month, date.day, value.hour, value.minute);

DateTime withSessionTime(DateTime value, M3ETime time) =>
    DateTime(value.year, value.month, value.day, time.hour, time.minute);

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
