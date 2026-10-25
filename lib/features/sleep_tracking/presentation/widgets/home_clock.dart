import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/time/clock_format.dart';

/// The hero block of Home: the live clock, the date and the session line.
class HomeClock extends StatelessWidget {
  const HomeClock({super.key, required this.now, required this.sessionLine});

  final DateTime now;
  final String sessionLine;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final use24HourFormat = MediaQuery.alwaysUse24HourFormatOf(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ClockLine(
          now: now,
          use24HourFormat: use24HourFormat,
          clockStyle: theme.typography.emphasized.displayLarge.copyWith(
            color: scheme.onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          periodStyle: theme.typography.baseline.titleMedium.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formatClockDate(now),
          textAlign: TextAlign.center,
          style: theme.typography.baseline.bodyMedium.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          liveRegion: true,
          child: Text(
            sessionLine,
            textAlign: TextAlign.center,
            style: theme.typography.emphasized.bodyMedium.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// The clock itself, with the 12-hour period set in `titleMedium`.
class _ClockLine extends StatelessWidget {
  const _ClockLine({
    required this.now,
    required this.use24HourFormat,
    required this.clockStyle,
    required this.periodStyle,
  });

  final DateTime now;
  final bool use24HourFormat;
  final TextStyle clockStyle;
  final TextStyle periodStyle;

  @override
  Widget build(BuildContext context) {
    final clock = formatClockTime(now, use24HourFormat: use24HourFormat);
    final period = formatDayPeriod(now);

    return Semantics(
      label:
          'Current time '
          '${formatClockLabel(now, use24HourFormat: use24HourFormat)}',
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return MediaQuery.withClampedTextScaling(
              maxScaleFactor: _maxTextScale(
                context,
                constraints,
                clock: clock,
                period: use24HourFormat ? null : period,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(clock, style: clockStyle),
                  if (!use24HourFormat) ...[
                    const SizedBox(width: 8),
                    Text(period, style: periodStyle),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Caps the clock's text scale so the single line never overflows.
  ///
  /// A clock is one unbreakable line of digits: wrapping it or clipping it
  /// would break the screen, so it scales down to the available width instead
  /// of growing past it. Every other text on the screen still follows the
  /// system scale. This is a layout decision, not an M3 rule.
  double _maxTextScale(
    BuildContext context,
    BoxConstraints constraints, {
    required String clock,
    required String? period,
  }) {
    final systemScale = MediaQuery.textScalerOf(context).scale(1);
    if (!constraints.hasBoundedWidth || constraints.maxWidth <= 0) {
      return systemScale;
    }

    final direction = Directionality.of(context);
    final defaultStyle = DefaultTextStyle.of(context).style;
    var textWidth = _unscaledWidth(
      clock,
      defaultStyle.merge(clockStyle),
      direction,
    );
    // The gap between the clock and the period is a fixed 8dp and does not
    // scale with the text, so it is subtracted before fitting the text.
    var gap = 0.0;
    if (period != null) {
      textWidth += _unscaledWidth(
        period,
        defaultStyle.merge(periodStyle),
        direction,
      );
      gap = 8;
    }
    final available = constraints.maxWidth - gap;
    if (textWidth <= 0 || available <= 0) return systemScale;

    final fittingScale = available / textWidth;
    return fittingScale < systemScale ? fittingScale : systemScale;
  }

  double _unscaledWidth(String text, TextStyle style, TextDirection direction) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: direction,
      textScaler: TextScaler.noScaling,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }
}
