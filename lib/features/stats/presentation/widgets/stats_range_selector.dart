import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../../sleep_tracking/domain/sleep_history.dart';

/// Single-select filter chips for the Stats range.
///
/// From M3: filter chips are 32dp tall with an 8dp corner and 8dp between
/// chips. A selected chip shows a leading checkmark as well as the selected
/// colors, so selection does not rely on color alone.
class StatsRangeSelector extends StatelessWidget {
  const StatsRangeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final SleepHistoryRange selected;
  final ValueChanged<SleepHistoryRange> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return M3EChipGroup(
      groupLabel: l10n.timeRange,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final range in SleepHistoryRange.values)
            M3EChip(
              type: M3EChipType.filter,
              label: _label(l10n, range),
              selected: range == selected,
              leading: range == selected
                  ? const Icon(M3EIcons.check, size: 18)
                  : null,
              onPressed: () {
                if (range != selected) onChanged(range);
              },
            ),
        ],
      ),
    );
  }

  String _label(AppLocalizations l10n, SleepHistoryRange range) {
    return switch (range) {
      SleepHistoryRange.sevenDays => l10n.range7Days,
      SleepHistoryRange.thirtyDays => l10n.range30Days,
      SleepHistoryRange.all => l10n.rangeAll,
    };
  }
}
