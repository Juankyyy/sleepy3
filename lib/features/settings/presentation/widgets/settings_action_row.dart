import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

/// A tappable Settings row with the same filled surface as the grouped lists.
///
/// It allows the headline and supporting text to wrap at large text scales,
/// which [M3EListItem] cannot do because it clamps the headline to one line.
/// Like [SettingsToggleRow], it lives outside `M3EList` and carries its own
/// 16dp surface so the label stays readable at 200% text.
class SettingsActionRow extends StatelessWidget {
  const SettingsActionRow({
    super.key,
    required this.showLeading,
    required this.leadingIcon,
    required this.headline,
    required this.supporting,
    required this.onTap,
    this.trailing,
  });

  final bool showLeading;
  final IconData leadingIcon;
  final String headline;
  final String supporting;
  final VoidCallback onTap;

  /// Optional status or action icon. Defaults to the chevron used by
  /// navigation rows.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final rowStyle = theme.typography.baseline.bodyLarge.copyWith(
      color: scheme.onSurface,
    );
    final supportStyle = theme.typography.baseline.bodyMedium.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return Semantics(
      container: true,
      excludeSemantics: true,
      button: true,
      label: headline,
      hint: supporting,
      onTap: onTap,
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  if (showLeading) ...[
                    Icon(leadingIcon, size: 24, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(headline, style: rowStyle),
                        const SizedBox(height: 2),
                        Text(supporting, style: supportStyle),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  trailing ??
                      Icon(
                        M3EIcons.chevron_right,
                        size: 24,
                        color: scheme.onSurfaceVariant,
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
