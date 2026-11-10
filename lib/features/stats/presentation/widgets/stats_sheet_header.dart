import 'dart:math' as math;

import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/l10n.dart';

/// The close button size used to measure both Stats sheets.
///
/// `M3EIconButtonSize.md` maps to the 56dp `M3EButtonSize.md` container.
const statsSheetHeaderCloseSize = 56.0;

/// Measures the shared pinned header with the current text scale.
double statsSheetHeaderExtent(
  BuildContext context, {
  required String title,
  required String support,
  required TextStyle titleStyle,
  required TextStyle supportStyle,
  required double titleWidth,
}) {
  final textScaler = MediaQuery.textScalerOf(context);
  final direction = Directionality.of(context);

  final titlePainter = TextPainter(
    text: TextSpan(text: title, style: titleStyle),
    textDirection: direction,
    textScaler: textScaler,
  )..layout(maxWidth: titleWidth);
  final supportPainter = TextPainter(
    text: TextSpan(text: support, style: supportStyle),
    textDirection: direction,
    textScaler: textScaler,
  )..layout(maxWidth: titleWidth);

  final rowHeight = math.max(
    titlePainter.height + 2 + supportPainter.height,
    statsSheetHeaderCloseSize,
  );
  // Top padding, handle, gap, row and bottom padding.
  return 10 + 4 + 10 + rowHeight + 12;
}

/// The shared pinned header for the Stats sheets.
///
/// It owns the handle, title, one supporting line, close button and the 1dp
/// `outlineVariant` border that separates the header from the scrolling body.
/// Both the advanced dashboard and the summary picker use it so their chrome
/// cannot diverge.
class StatsSheetHeaderDelegate extends SliverPersistentHeaderDelegate {
  const StatsSheetHeaderDelegate({
    required this.extent,
    required this.title,
    required this.support,
    required this.margin,
    required this.titleStyle,
    required this.supportStyle,
    required this.onClose,
    this.contentKey,
    this.borderKey,
    this.handleKey,
  });

  final double extent;
  final String title;
  final String support;
  final double margin;
  final TextStyle titleStyle;
  final TextStyle supportStyle;
  final VoidCallback onClose;
  final Key? contentKey;
  final Key? borderKey;
  final Key? handleKey;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return SizedBox(
      key: contentKey,
      height: extent,
      child: DecoratedBox(
        key: borderKey,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          border: Border(
            bottom: BorderSide(color: scheme.outlineVariant, width: 1),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(margin, 10, margin, 12),
          child: Column(
            children: [
              Center(
                child: Container(
                  key: handleKey,
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.40),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // 10dp separates the handle from the title row.
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            style: titleStyle.copyWith(color: scheme.onSurface),
                          ),
                        ),
                        // 2dp keeps the supporting line attached to the title.
                        const SizedBox(height: 2),
                        Text(
                          support,
                          style: supportStyle.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  M3EIconButton(
                    icon: const Icon(M3EIcons.close),
                    variant: M3EIconButtonVariant.standard,
                    size: M3EIconButtonSize.md,
                    tooltip: l10n.close,
                    onPressed: onClose,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant StatsSheetHeaderDelegate oldDelegate) => true;
}
