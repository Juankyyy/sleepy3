import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import 'bento_badge.dart';
import 'bento_figure.dart';
import 'settings_tones.dart';

/// The two widths of the Settings bento cards.
enum BentoCardSize { wide, half }

/// A tonal Settings card with a scalloped icon badge and an M3 figure.
///
/// The card is either directly actionable ([onTap] with no footer actions), a
/// toggle ([toggled] plus [onTap], with the switch drawn only as a visual
/// state), or a plain container. The optional [footer] lives outside the
/// toggle's semantics so it can hold a separate action such as the reminder
/// time picker. The whole card is a single tap target; the footer actions sit
/// above that surface and keep their own gestures.
class BentoCard extends StatelessWidget {
  const BentoCard({
    super.key,
    required this.tone,
    required this.size,
    required this.icon,
    required this.title,
    required this.figure,
    this.supporting,
    this.footer,
    this.trailing,
    this.body,
    this.onTap,
    this.toggled,
    this.semanticLabel,
    this.semanticHint,
    this.minHeight,
    this.padding = const EdgeInsets.all(14),
  }) : assert(
         onTap != null || toggled == null,
         'A toggle card needs an onTap callback',
       );

  final SettingsTone tone;
  final BentoCardSize size;
  final IconData icon;
  final String title;
  final BentoFigureShape figure;
  final String? supporting;

  /// A separate action below the main block, such as the reminder time chip.
  final Widget? footer;

  /// The top-right visual: a chevron for navigation, a switch for a toggle.
  final Widget? trailing;

  /// Replaces the default title/supporting block.
  final Widget? body;

  /// Whole-card action. Null for a plain container.
  final VoidCallback? onTap;

  /// When set, the card is announced as a switch. Requires [onTap].
  final bool? toggled;

  final String? semanticLabel;
  final String? semanticHint;
  final double? minHeight;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final titleStyle = _titleStyle(context);
    final supportStyle = _supportStyle(context);
    final gap = size == BentoCardSize.wide ? 26.0 : 18.0;

    final main = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BentoBadge(
              icon: icon,
              shape: figure,
              size: size == BentoCardSize.wide ? 48 : 44,
              containerColor: tone.iconContainer,
              iconColor: tone.icon,
            ),
            const Spacer(),
            ?trailing,
          ],
        ),
        SizedBox(height: gap),
        if (body != null)
          body!
        else ...[
          Text(title, style: titleStyle),
          if (supporting != null) ...[
            const SizedBox(height: 3),
            Text(supporting!, style: supportStyle),
          ],
        ],
      ],
    );

    final navigation = onTap != null && toggled == null && footer == null;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (navigation) main else _wrapSemantics(main),
        if (footer != null) ...[const SizedBox(height: 8), footer!],
      ],
    );

    Widget card = Stack(
      children: [
        Positioned.fill(
          child: BentoFigure(
            shape: figure,
            color: tone.blob,
            placement: size == BentoCardSize.wide
                ? BentoFigurePlacement.wideRaised
                : BentoFigurePlacement.half,
            widthFactor: size == BentoCardSize.half ? 0.95 : 0.68,
          ),
        ),
        Padding(padding: padding, child: content),
      ],
    );

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        excludeFromSemantics: true,
        borderRadius: BorderRadius.circular(24),
        overlayColor: WidgetStatePropertyAll(
          tone.onBackground.withValues(alpha: 0.08),
        ),
        splashColor: tone.onBackground.withValues(alpha: 0.08),
        highlightColor: tone.onBackground.withValues(alpha: 0.06),
        child: card,
      );
    }

    if (navigation) {
      card = Semantics(
        container: true,
        button: true,
        excludeSemantics: true,
        label: semanticLabel ?? title,
        hint: semanticHint ?? supporting,
        onTap: onTap,
        child: card,
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: minHeight ?? (size == BentoCardSize.wide ? 126 : 150),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(color: tone.background, child: card),
      ),
    );
  }

  Widget _wrapSemantics(Widget child) {
    if (toggled != null) {
      return Semantics(
        container: true,
        excludeSemantics: true,
        toggled: toggled,
        label: semanticLabel ?? title,
        hint: semanticHint ?? supporting,
        onTap: onTap,
        child: child,
      );
    }
    if (onTap != null) {
      return Semantics(
        container: true,
        button: true,
        excludeSemantics: true,
        label: semanticLabel ?? title,
        hint: semanticHint ?? supporting,
        onTap: onTap,
        child: child,
      );
    }
    return child;
  }

  TextStyle _titleStyle(BuildContext context) {
    final typography = M3ETheme.of(context).typography;
    final style = size == BentoCardSize.wide
        ? typography.emphasized.titleLarge
        : typography.emphasized.titleMedium;
    return style.copyWith(color: tone.onBackground);
  }

  TextStyle _supportStyle(BuildContext context) {
    final typography = M3ETheme.of(context).typography;
    final style = size == BentoCardSize.wide
        ? typography.baseline.bodyMedium
        : typography.baseline.bodySmall;
    return style.copyWith(color: tone.supporting);
  }
}

/// The card title style, shared by cards that replace the default [BentoCard]
/// body (the goal card).
TextStyle bentoTitleStyle(
  BuildContext context,
  BentoCardSize size,
  Color color,
) {
  final typography = M3ETheme.of(context).typography;
  final style = size == BentoCardSize.wide
      ? typography.emphasized.titleLarge
      : typography.emphasized.titleMedium;
  return style.copyWith(color: color);
}

/// The card supporting style for custom bodies.
TextStyle bentoSupportStyle(
  BuildContext context,
  BentoCardSize size,
  Color color,
) {
  final typography = M3ETheme.of(context).typography;
  final style = size == BentoCardSize.wide
      ? typography.baseline.bodyMedium
      : typography.baseline.bodySmall;
  return style.copyWith(color: color);
}
