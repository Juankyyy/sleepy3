import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

/// A centered icon, headline and supporting line for screens without content.
///
/// M3 has no empty-state component. This is a small pattern built from M3
/// parts: a 48dp symbol, `headlineSmall` and `bodyMedium`, with 16dp compact
/// margins and 4dp-step spacing. The screen keeps this state until its content
/// is designed.
class Sleepy3EmptyState extends StatelessWidget {
  const Sleepy3EmptyState({
    super.key,
    required this.icon,
    required this.headline,
    required this.supportingText,
    this.scrollable = true,
  });

  final IconData icon;
  final String headline;
  final String supportingText;

  /// Whether this state owns a scroll view.
  ///
  /// Set to false when the parent already provides one, such as the Stats
  /// pull-to-refresh scroll view, so the state does not nest scrollables.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48, color: scheme.onSurfaceVariant),
        const SizedBox(height: 16),
        Text(
          headline,
          textAlign: TextAlign.center,
          style: theme.typography.baseline.headlineSmall.copyWith(
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          supportingText,
          textAlign: TextAlign.center,
          style: theme.typography.baseline.bodyMedium.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    return Center(
      child: scrollable
          ? SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: content,
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: content,
            ),
    );
  }
}
