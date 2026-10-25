import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

/// A grouped Settings list with the same expressive radii and gaps as Stats.
///
/// From M3: a contained list uses rounded corners and gaps instead of
/// dividers. The 16/4 dp radii and 2 dp gap match the list pattern already
/// established on the Stats screen.
class SettingsList extends StatelessWidget {
  const SettingsList({super.key, required this.children, this.onTap});

  final List<Widget> children;

  /// Row action for a single-action list.
  ///
  /// `M3EList` routes taps at the list level, so the item's own `onTap` is
  /// ignored while it is embedded in a list.
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    return M3EList(
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
      onTap: onTap,
      variant: M3ECardVariant.filled,
      outerRadius: 16,
      innerRadius: 4,
      gap: 2,
    );
  }
}
