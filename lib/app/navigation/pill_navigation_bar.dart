import 'dart:math' as math;
import 'dart:ui' show ImageFilter, SemanticsRole;

import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/l10n.dart';
import 'sleepy3_destination.dart';

const double _navInnerPadding = 8;
const double _navItemGap = 8;
const double _navItemContentInset = 12;
const double _navItemIconLabelGap = 12;
const double _navItemMinHeight = 48;
const double _navItemLabelVerticalPadding = 12;
const double _navMeasurementSlack = 2;
const double _navOvershootSlack = 8;
const double _navFocusRingInset = 3;
const double _navFocusRingWidth = 3;
const double _navGlassBlur = 16;
const double _navGlassOpacity = 0.82;
const double _navGlassBorderOpacity = 0.55;

/// The floating pill navigation bar used by the three top-level destinations.
///
/// The glass container is content-sized and centered, with a 64 dp height at
/// 1x; it grows vertically when a scaled label needs another line. The selected
/// destination expands into an opaque pill that holds its filled icon and its
/// label; inactive destinations show only their outlined icon. Inactive labels
/// stay in the semantics tree.
///
/// An optional [trailing] action (the Stats FAB) sits beside the glass with
/// [trailingGap] between them. The two are centered as one group, so the action
/// is never pinned to the screen edge; the glass measurement leaves room for
/// the trailing width.
///
/// The scaffold extends its body behind the bar ([Scaffold.extendBody]) so
/// content stays visible through the glass; screens add the bottom
/// `MediaQuery` padding as scroll clearance.
///
/// This is intentionally not [M3ENavigationBar]: M3 requires a full-width
/// container, an opaque surface and a label on every destination. Sleepy3
/// follows the compact, floating glass reference requested for the app; the
/// deviation is documented in `SPEC.md`.
class PillNavigationBar extends StatefulWidget {
  const PillNavigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.semanticLabel,
    this.trailing,
    this.trailingGap = 12,
    this.trailingWidth = 56,
  }) : assert(destinations.length > 0, 'Provide at least one destination'),
       assert(trailingWidth >= 0, 'The trailing width cannot be negative');

  /// Minimum container height at 1x text.
  static const double minHeight = 64;

  /// Minimum horizontal gap between the content-sized bar and the screen.
  static const double outerMargin = 16;

  /// Minimum horizontal gap on windows narrower than 360 dp.
  static const double compactOuterMargin = 12;

  /// Gap between the bar and the safe area bottom.
  static const double bottomGap = 12;

  /// Gap between the page content and the floating bar.
  static const double topGap = 8;

  /// The glass container. Tests use it to measure the centered bar.
  static const Key surfaceKey = ValueKey('pill-navigation-surface');

  final List<Sleepy3Destination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final String? semanticLabel;

  /// Optional action rendered beside the glass, such as the Stats FAB.
  ///
  /// It is centered with the glass as one group and keeps the action away from
  /// the screen edge. It lives inside the bar's 64 dp height, so screens do not
  /// need extra bottom clearance for it.
  final Widget? trailing;

  /// Gap between the glass and [trailing].
  final double trailingGap;

  /// Width reserved for [trailing]. The widget should match this width.
  final double trailingWidth;

  @override
  State<PillNavigationBar> createState() => _PillNavigationBarState();
}

class _PillNavigationBarState extends State<PillNavigationBar> {
  late List<FocusNode> _focusNodes;

  int get _selectedIndex {
    final index = widget.selectedIndex;
    if (index < 0) return 0;
    if (index >= widget.destinations.length) {
      return widget.destinations.length - 1;
    }
    return index;
  }

  @override
  void initState() {
    super.initState();
    _focusNodes = _buildFocusNodes();
  }

  @override
  void didUpdateWidget(covariant PillNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.destinations.length != widget.destinations.length) {
      for (final node in _focusNodes) {
        node.dispose();
      }
      _focusNodes = _buildFocusNodes();
    }
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  List<FocusNode> _buildFocusNodes() {
    return [
      for (final destination in widget.destinations)
        FocusNode(debugLabel: 'PillNavigationBar[${destination.name}]'),
    ];
  }

  void _moveFocus(int delta) {
    if (_focusNodes.isEmpty) return;
    final current = _focusNodes.indexWhere((node) => node.hasFocus);
    if (current < 0) {
      _focusNodes[_selectedIndex].requestFocus();
      return;
    }
    final direction = Directionality.of(context) == TextDirection.rtl
        ? -delta
        : delta;
    final next = (current + direction).clamp(0, _focusNodes.length - 1).toInt();
    if (next != current) {
      _focusNodes[next].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final navigationTheme = theme.navigationBarTheme;
    final labelStyle = navigationTheme.labelStyle(
      theme.typography.baseline,
      selected: true,
    );
    final l10n = AppLocalizations.of(context);
    final labels = [
      for (final destination in widget.destinations) destination.label(l10n),
    ];
    final textScaler = MediaQuery.textScalerOf(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final outerMargin = screenWidth < 360
        ? PillNavigationBar.compactOuterMargin
        : PillNavigationBar.outerMargin;
    final iconSize = navigationTheme.iconSize;

    return LayoutBuilder(
      builder: (context, constraints) {
        final trailingSpace = widget.trailing == null
            ? 0.0
            : widget.trailingWidth + widget.trailingGap;
        final maxBarWidth = math.max(
          0.0,
          constraints.maxWidth - outerMargin * 2 - trailingSpace,
        );
        final contentMaxWidth = math.max(
          0.0,
          maxBarWidth -
              _navInnerPadding * 2 -
              _navItemGap * (widget.destinations.length - 1),
        );
        final metrics = _measureDestinations(
          context: context,
          labels: labels,
          labelStyle: labelStyle,
          textScaler: textScaler,
          iconSize: iconSize,
          availableWidth: contentMaxWidth,
        );
        final barHeight = metrics.itemHeight + _navInnerPadding * 2;

        final items = <Widget>[
          for (var i = 0; i < widget.destinations.length; i++)
            _PillNavigationItem(
              key: ValueKey(widget.destinations[i]),
              destination: widget.destinations[i],
              label: labels[i],
              selected: i == _selectedIndex,
              targetWidth: metrics.targetWidths[i],
              maxWidth: math.min(
                metrics.targetWidths[i] + _navOvershootSlack,
                metrics.maxSelectedWidth,
              ),
              height: metrics.itemHeight,
              labelStyle: labelStyle,
              labelWidth: metrics.labelBoxWidths[i],
              navigationTheme: navigationTheme,
              scheme: scheme,
              focusNode: _focusNodes[i],
              onTap: () => widget.onDestinationSelected(i),
            ),
        ];

        final glass = ClipRRect(
          key: PillNavigationBar.surfaceKey,
          borderRadius: BorderRadius.circular(barHeight / 2),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: _navGlassBlur,
              sigmaY: _navGlassBlur,
            ),
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: navigationTheme
                    .containerColor(scheme)
                    .withValues(alpha: _navGlassOpacity),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: scheme.outlineVariant.withValues(
                      alpha: _navGlassBorderOpacity,
                    ),
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(_navInnerPadding),
                child: CallbackShortcuts(
                  bindings: <ShortcutActivator, VoidCallback>{
                    const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
                        _moveFocus(-1),
                    const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
                        _moveFocus(1),
                  },
                  child: FocusTraversalGroup(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: _navItemGap,
                      children: items,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Semantics(
              container: true,
              label: widget.semanticLabel,
              child: glass,
            ),
            if (widget.trailing != null) ...[
              SizedBox(width: widget.trailingGap),
              // Keep the slot even while the action hides itself, so the glass
              // does not move when the FAB appears after the history loads.
              // The explicit height stops the Center from expanding to the
              // Scaffold's full height and floating the whole bar mid-screen.
              SizedBox(
                width: widget.trailingWidth,
                height: widget.trailingWidth,
                child: Center(child: widget.trailing),
              ),
            ],
          ],
        );
      },
    );
  }

  _DestinationMetrics _measureDestinations({
    required BuildContext context,
    required List<String> labels,
    required TextStyle labelStyle,
    required TextScaler textScaler,
    required double iconSize,
    required double availableWidth,
  }) {
    final collapsedWidth = iconSize + _navItemContentInset * 2;
    final maxSelectedWidth = math.max(
      collapsedWidth,
      availableWidth -
          collapsedWidth * (widget.destinations.length - 1) -
          _navOvershootSlack,
    );

    final labelBoxWidths = <double>[];
    final selectedWidths = <double>[];
    var maxLabelHeight = 0.0;
    for (var index = 0; index < widget.destinations.length; index++) {
      final label = labels[index];
      final naturalPainter = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textScaler: textScaler,
        textDirection: Directionality.of(context),
        maxLines: 1,
      )..layout();
      final naturalWidth = naturalPainter.width + _navMeasurementSlack;
      naturalPainter.dispose();

      final selectedWidth = math.min(
        collapsedWidth + _navItemIconLabelGap + naturalWidth,
        maxSelectedWidth,
      );
      final labelBoxWidth = math.max(
        0.0,
        selectedWidth - collapsedWidth - _navItemIconLabelGap,
      );
      selectedWidths.add(selectedWidth);
      labelBoxWidths.add(labelBoxWidth);

      final heightPainter = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textScaler: textScaler,
        textDirection: Directionality.of(context),
        maxLines: 2,
        textAlign: TextAlign.start,
      )..layout(maxWidth: math.max(1, labelBoxWidth));
      maxLabelHeight = math.max(maxLabelHeight, heightPainter.height);
      heightPainter.dispose();
    }

    final targetWidths = <double>[
      for (var i = 0; i < widget.destinations.length; i++)
        if (i == _selectedIndex) selectedWidths[i] else collapsedWidth,
    ];
    final itemHeight = math.max(
      _navItemMinHeight,
      maxLabelHeight + _navItemLabelVerticalPadding,
    );
    return _DestinationMetrics(
      labelBoxWidths: labelBoxWidths,
      targetWidths: targetWidths,
      maxSelectedWidth: maxSelectedWidth,
      itemHeight: itemHeight,
    );
  }
}

/// Width and height used by one destination in the current build.
class _DestinationMetrics {
  const _DestinationMetrics({
    required this.labelBoxWidths,
    required this.targetWidths,
    required this.maxSelectedWidth,
    required this.itemHeight,
  });

  final List<double> labelBoxWidths;
  final List<double> targetWidths;
  final double maxSelectedWidth;
  final double itemHeight;
}

/// One destination inside [PillNavigationBar].
///
/// The width springs between the collapsed icon chip and the selected
/// icon-plus-label pill. The label is clipped by the item width, so it reveals
/// itself as the pill grows; the color fade uses the effects spring.
class _PillNavigationItem extends StatefulWidget {
  const _PillNavigationItem({
    super.key,
    required this.destination,
    required this.label,
    required this.selected,
    required this.targetWidth,
    required this.maxWidth,
    required this.height,
    required this.labelStyle,
    required this.labelWidth,
    required this.navigationTheme,
    required this.scheme,
    required this.focusNode,
    required this.onTap,
  });

  final Sleepy3Destination destination;
  final String label;
  final bool selected;
  final double targetWidth;
  final double maxWidth;
  final double height;
  final TextStyle labelStyle;
  final double labelWidth;
  final M3ENavigationBarTheme navigationTheme;
  final M3EColorScheme scheme;
  final FocusNode focusNode;
  final VoidCallback onTap;

  @override
  State<_PillNavigationItem> createState() => _PillNavigationItemState();
}

class _PillNavigationItemState extends State<_PillNavigationItem>
    with TickerProviderStateMixin {
  late final AnimationController _width;
  late final AnimationController _effect;
  late final Listenable _animation;

  double get _collapsedWidth =>
      widget.navigationTheme.iconSize + _navItemContentInset * 2;

  @override
  void initState() {
    super.initState();
    _width = AnimationController.unbounded(
      vsync: this,
      value: widget.targetWidth,
    );
    _effect = AnimationController.unbounded(
      vsync: this,
      value: widget.selected ? 1 : 0,
    );
    _animation = Listenable.merge(<Listenable>[_width, _effect]);
  }

  @override
  void didUpdateWidget(covariant _PillNavigationItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetWidth != widget.targetWidth) {
      _width.animateWith(
        SpringSimulation(
          M3EMotion.expressiveSpatialFast.toDescription(),
          _width.value,
          widget.targetWidth,
          0,
        ),
      );
    }
    if (oldWidget.selected != widget.selected) {
      _effect.animateWith(
        SpringSimulation(
          M3EMotion.effectsFast.toDescription(),
          _effect.value,
          widget.selected ? 1 : 0,
          0,
        ),
      );
    }
  }

  @override
  void dispose() {
    _width.dispose();
    _effect.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigationTheme = widget.navigationTheme;
    final scheme = widget.scheme;
    final inactiveColor = navigationTheme.unselectedColor(scheme);
    final activeColor = navigationTheme.selectedColor(scheme);
    final activeLabelColor = navigationTheme.activeLabelColor(scheme);
    final indicatorColor = navigationTheme.indicatorColor(scheme);
    final contentWidth =
        _collapsedWidth + _navItemIconLabelGap + widget.labelWidth;

    return Semantics(
      key: ValueKey('nav-${widget.destination.name}'),
      role: SemanticsRole.tab,
      selected: widget.selected,
      label: widget.label,
      onTap: widget.onTap,
      child: M3ETappable(
        focusNode: widget.focusNode,
        onTap: widget.onTap,
        focusOverlay: false,
        materialInk: false,
        semanticButton: false,
        excludeSemantics: true,
        builder: (context, state) {
          return AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              final width = _width.value.clamp(
                _collapsedWidth,
                widget.maxWidth,
              );
              final effect = _effect.value.clamp(0.0, 1.0);
              final pillColor = Color.lerp(
                indicatorColor.withValues(alpha: 0),
                indicatorColor,
                effect,
              )!;

              return SizedBox(
                width: width,
                height: widget.height,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: pillColor,
                    shape: const StadiumBorder(),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (state.hovered || state.focused || state.pressed)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: ShapeDecoration(
                                color: navigationTheme
                                    .stateLayerColor(scheme)
                                    .withValues(alpha: _overlayOpacity(state)),
                                shape: const StadiumBorder(),
                              ),
                            ),
                          ),
                        ),
                      Positioned.fill(
                        child: ClipRect(
                          child: OverflowBox(
                            alignment: Alignment.centerLeft,
                            minWidth: contentWidth,
                            maxWidth: contentWidth,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: _navItemContentInset,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    widget.selected
                                        ? widget.destination.selectedIcon
                                        : widget.destination.icon,
                                    size: navigationTheme.iconSize,
                                    color: Color.lerp(
                                      inactiveColor,
                                      activeColor,
                                      effect,
                                    ),
                                  ),
                                  const SizedBox(width: _navItemIconLabelGap),
                                  SizedBox(
                                    width: widget.labelWidth,
                                    child: Text(
                                      widget.label,
                                      maxLines: 2,
                                      softWrap: true,
                                      textAlign: TextAlign.start,
                                      overflow: TextOverflow.clip,
                                      style: widget.labelStyle.copyWith(
                                        color: activeLabelColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (state.focused)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Padding(
                              padding: const EdgeInsets.all(_navFocusRingInset),
                              child: DecoratedBox(
                                decoration: ShapeDecoration(
                                  shape: StadiumBorder(
                                    side: BorderSide(
                                      color: navigationTheme.focusRingColor(
                                        scheme,
                                      ),
                                      width: _navFocusRingWidth,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  double _overlayOpacity(M3EInteractionState state) {
    if (state.pressed) return widget.navigationTheme.pressedOpacity;
    if (state.focused) return widget.navigationTheme.focusOpacity;
    if (state.hovered) return widget.navigationTheme.hoverOpacity;
    return 0;
  }
}
