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
  });

  final IconData icon;
  final String headline;
  final String supportingText;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
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
        ),
      ),
    );
  }
}
