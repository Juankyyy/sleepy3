import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/time/day_phase.dart';

/// The centered brand and the day/night status at the top of Home.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.phase});

  final DayPhase phase;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Sleepy3',
            textAlign: TextAlign.center,
            style: theme.typography.emphasized.headlineLarge.copyWith(
              color: scheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _DayNightStatus(phase: phase),
      ],
    );
  }
}

/// The day/night status pill.
///
/// This is not an M3 chip: chips are interactive, and this label only reports
/// state. It borrows the chip's 32dp container (8dp vertical padding around
/// `labelMedium`), 16dp side padding and the full shape from the M3 shape
/// scale, with `secondaryContainer` / `onSecondaryContainer` as the status
/// pair.
class _DayNightStatus extends StatelessWidget {
  const _DayNightStatus({required this.phase});

  final DayPhase phase;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final label = switch (phase) {
      DayPhase.day => 'Day · ready to wake',
      DayPhase.night => 'Night · time to rest',
    };
    final spokenLabel = switch (phase) {
      DayPhase.day => 'Day, ready to wake',
      DayPhase.night => 'Night, time to rest',
    };

    return Semantics(
      label: spokenLabel,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: ShapeDecoration(
            color: scheme.secondaryContainer,
            shape: M3EShapes.stadium,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.typography.baseline.labelMedium.copyWith(
              color: scheme.onSecondaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}
