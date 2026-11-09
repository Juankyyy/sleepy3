import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

/// A Settings switch row with the same filled list surface as the other lists.
///
/// It is not an [M3EListItem] because that item clamps its headline to one
/// line and excludes child semantics, which hides the switch from TalkBack.
class SettingsToggleRow extends StatelessWidget {
  const SettingsToggleRow({
    super.key,
    required this.showLeading,
    required this.leadingIcon,
    required this.enabled,
    required this.busy,
    required this.headline,
    required this.supporting,
    required this.onChanged,
    this.switchKey,
  });

  final bool showLeading;
  final IconData leadingIcon;
  final bool enabled;
  final bool busy;
  final String headline;
  final String supporting;
  final ValueChanged<bool> onChanged;

  /// Optional key for the switch itself, used by widget tests when the screen
  /// has more than one toggle row.
  final Key? switchKey;

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
    void toggle() {
      if (!busy) onChanged(!enabled);
    }

    return Semantics(
      container: true,
      excludeSemantics: true,
      toggled: enabled,
      label: headline,
      hint: supporting,
      enabled: !busy,
      onTap: busy ? null : toggle,
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: busy ? null : toggle,
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
                  ExcludeSemantics(
                    child: IgnorePointer(
                      child: M3ESwitch(
                        key: switchKey,
                        value: enabled,
                        onChanged: busy ? null : (_) {},
                      ),
                    ),
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
