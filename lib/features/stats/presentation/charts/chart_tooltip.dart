import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import 'chart_motion.dart';
import 'chart_theme.dart';

/// The two tooltip styles used by the charts.
enum ChartTooltipVariant { plain, rich }

/// Chart tooltip with the M3 plain and rich tooltip styles.
///
/// From M3: plain tooltips are 24dp tall, use 8dp padding, radius 4dp and
/// `inverseSurface` / `onInverseSurface`. Rich tooltips use radius 12dp,
/// `surfaceContainer` / `onSurfaceVariant`, 12dp top padding, 8dp bottom
/// padding and 16dp side padding.
class ChartTooltip extends StatelessWidget {
  const ChartTooltip.plain({super.key, required this.label})
    : variant = ChartTooltipVariant.plain,
      title = null,
      supporting = null;

  const ChartTooltip.rich({
    super.key,
    required this.label,
    this.title,
    this.supporting,
  }) : variant = ChartTooltipVariant.rich;

  final String label;
  final String? title;
  final String? supporting;
  final ChartTooltipVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      container: true,
      liveRegion: true,
      label: label,
      child: ExcludeSemantics(
        child: switch (variant) {
          ChartTooltipVariant.plain => _PlainTooltip(
            label: label,
            container: scheme.inverseSurface,
            textStyle: theme.typography.baseline.labelMedium.copyWith(
              color: scheme.onInverseSurface,
            ),
          ),
          ChartTooltipVariant.rich => _RichTooltip(
            label: label,
            title: title,
            supporting: supporting,
            container: scheme.surfaceContainer,
            textStyle: theme.typography.baseline.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            titleStyle: theme.typography.emphasized.titleSmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        },
      ),
    );
  }
}

class _PlainTooltip extends StatelessWidget {
  const _PlainTooltip({
    required this.label,
    required this.container,
    required this.textStyle,
  });

  final String label;
  final Color container;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ChartDimensions.plainTooltipPadding,
        // 24dp container with the 16dp labelMedium line leaves 4dp top and
        // bottom. At larger text scales the container grows instead of
        // clipping the label.
        vertical: (ChartDimensions.plainTooltipHeight - 16) / 2,
      ),
      decoration: BoxDecoration(
        color: container,
        borderRadius: M3EShapes.radiusExtraSmall,
      ),
      child: Text(
        label,
        style: textStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _RichTooltip extends StatelessWidget {
  const _RichTooltip({
    required this.label,
    required this.title,
    required this.supporting,
    required this.container,
    required this.textStyle,
    required this.titleStyle,
  });

  final String label;
  final String? title;
  final String? supporting;
  final Color container;
  final TextStyle textStyle;
  final TextStyle titleStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: container,
        borderRadius: M3EShapes.radiusMedium,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: titleStyle),
            const SizedBox(height: 4),
          ],
          Text(label, style: textStyle),
          if (supporting != null) ...[
            const SizedBox(height: 4),
            Text(supporting!, style: textStyle),
          ],
        ],
      ),
    );
  }
}

/// Places a [ChartTooltip] above an anchor inside a chart `Stack`.
///
/// Use it as a `Positioned.fill` child; the widget itself returns a
/// `Positioned` entry. The tooltip sits 4dp above the visual boundary and flips
/// below the anchor when there is no room. Give it a `ValueKey` tied to the
/// selection so the `effectsFast` fade replays for every selected point.
class ChartTooltipLayer extends StatelessWidget {
  const ChartTooltipLayer({
    super.key,
    required this.anchor,
    required this.child,
  });

  final Offset anchor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomSingleChildLayout(
          delegate: _TooltipLayout(anchor: anchor),
          child: ChartFade(visible: true, child: child),
        ),
      ),
    );
  }
}

class _TooltipLayout extends SingleChildLayoutDelegate {
  const _TooltipLayout({required this.anchor});

  final Offset anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      maxWidth: constraints.maxWidth,
      maxHeight: constraints.maxHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final maxX = (size.width - childSize.width)
        .clamp(0.0, double.infinity)
        .toDouble();
    final maxY = (size.height - childSize.height)
        .clamp(0.0, double.infinity)
        .toDouble();
    final left = (anchor.dx - childSize.width / 2).clamp(0.0, maxX).toDouble();

    var top = anchor.dy - ChartDimensions.tooltipGap - childSize.height;
    if (top < 0) top = anchor.dy + ChartDimensions.tooltipGap;

    return Offset(left, top.clamp(0.0, maxY).toDouble());
  }

  @override
  bool shouldRelayout(covariant _TooltipLayout oldDelegate) =>
      oldDelegate.anchor != anchor;
}
