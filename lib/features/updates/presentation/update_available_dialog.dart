import 'dart:async';
import 'dart:ui' show SemanticsRole;

import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../domain/app_release.dart';
import '../domain/app_version_number.dart';
import '../domain/release_notes.dart';
import '../domain/update_prompt_action.dart';
import 'widgets/release_notes_view.dart';

/// The launch dialog for a newer release.
///
/// This is a basic dialog composed from the `M3EDialog` theme tokens because
/// the package's basic `M3EDialog` has no header close affordance. It keeps the
/// 28dp surface, 24dp padding and 1dp section dividers. The title and the
/// actions stay pinned; only the release notes scroll. The two actions are the
/// per-version opt-out and the download; they sit side by side on a wide
/// dialog and stack on a compact one, with the confirming action above the
/// dismissive one. The GitHub page is a content link under the release theme.
class UpdateAvailableDialog extends StatefulWidget {
  const UpdateAvailableDialog({
    super.key,
    required this.release,
    required this.installedVersion,
    required this.onOpenLink,
  });

  final AppRelease release;

  /// The installed version from `package_info_plus`, for example `0.4.0`.
  final String? installedVersion;

  /// Opens a link from the release notes. Returns false when it fails.
  final Future<bool> Function(Uri uri) onOpenLink;

  @override
  State<UpdateAvailableDialog> createState() => _UpdateAvailableDialogState();
}

class _UpdateAvailableDialogState extends State<UpdateAvailableDialog> {
  static const _previousVersionOpacity = 0.8;
  static const _maxHeightFraction = 0.85;
  static const _bodyInset = 8.0;
  // 28 (dialog) - 8 (inset) = 20, M3's nested-corner rule.
  static const _bodyRadius = 20.0;

  late ReleaseNotes _notes;
  bool _linkFailed = false;

  @override
  void initState() {
    super.initState();
    _notes = ReleaseNotes.parse(widget.release.notes);
  }

  @override
  void didUpdateWidget(covariant UpdateAvailableDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.release, widget.release)) {
      _notes = ReleaseNotes.parse(widget.release.notes);
      _linkFailed = false;
    }
  }

  Future<bool> _openLink(Uri uri) async {
    final opened = await widget.onOpenLink(uri);
    if (!mounted) return opened;

    if (opened) {
      if (_linkFailed) setState(() => _linkFailed = false);
    } else if (!_linkFailed) {
      setState(() => _linkFailed = true);
    }

    return opened;
  }

  String _semanticLabel(AppLocalizations l10n) {
    final installed = AppVersionNumber.tryParse(widget.installedVersion ?? '');
    if (installed == null || installed.toString() == widget.release.version) {
      return l10n.updateDialogSemantic(widget.release.version);
    }
    return l10n.updateDialogSemanticRange(
      installed.toString(),
      widget.release.version,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final dialogTheme = theme.dialogTheme;
    final appearance = dialogTheme.appearance;
    final l10n = context.l10n;

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      role: SemanticsRole.alertDialog,
      label: _semanticLabel(l10n),
      child: Container(
        constraints: BoxConstraints(
          minWidth: dialogTheme.minWidth,
          maxWidth: dialogTheme.maxWidth,
          // M3 publishes no basic-dialog max height. Keep the dialog from
          // filling the whole screen while the notes scroll inside it.
          maxHeight: MediaQuery.sizeOf(context).height * _maxHeightFraction,
        ),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: dialogTheme.containerColor(scheme),
          borderRadius: dialogTheme.borderRadius,
          boxShadow: M3EElevation.shadows(
            dialogTheme.elevation,
            shadowColor: scheme.shadow,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              title: l10n.updateDialogTitle,
              subtitle: _VersionSubtitle(
                release: widget.release,
                installedVersion: widget.installedVersion,
                previousVersionOpacity: _previousVersionOpacity,
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(_bodyInset),
                child: Container(
                  key: const ValueKey('update-dialog-body'),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: scheme.surfaceDim,
                    borderRadius: BorderRadius.circular(_bodyRadius),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.updateWhatsNew,
                          style: theme.typography.emphasized.titleSmall
                              .copyWith(color: scheme.onSurface),
                        ),
                        const SizedBox(height: 6),
                        if (_notes.isEmpty)
                          Text(
                            l10n.updateSummaryFallback,
                            style: appearance.resolveSupporting(theme),
                          )
                        else
                          ReleaseNotesView(
                            notes: _notes,
                            onOpenLink: _openLink,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_linkFailed)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  dialogTheme.padding.left,
                  8,
                  dialogTheme.padding.right,
                  0,
                ),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    l10n.updateOpenFailed,
                    style: theme.typography.baseline.bodySmall.copyWith(
                      color: scheme.error,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                dialogTheme.padding.left,
                12,
                dialogTheme.padding.right,
                16,
              ),
              child: _Actions(
                onDontRemind: () =>
                    Navigator.of(context)
                        .pop(UpdatePromptAction.dismissVersion),
                onDownload: () =>
                    Navigator.of(context).pop(UpdatePromptAction.download),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `v0.4.0 → v0.4.1 · The Bento Update`, with the installed version muted.
class _VersionSubtitle extends StatelessWidget {
  const _VersionSubtitle({
    required this.release,
    required this.installedVersion,
    required this.previousVersionOpacity,
  });

  final AppRelease release;
  final String? installedVersion;
  final double previousVersionOpacity;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final installed = AppVersionNumber.tryParse(installedVersion ?? '');
    final previous = installed?.toString();
    final target = release.version;
    final showRange = previous != null && previous != target;
    final themeName = release.displayName;
    final hasTheme = themeName != 'Sleepy3 $target';

    final baseStyle = theme.typography.baseline.bodyMedium.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final mutedStyle = baseStyle.copyWith(
      color: scheme.onSurfaceVariant.withValues(alpha: previousVersionOpacity),
    );

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (showRange) ...[
          Text('v$previous', style: mutedStyle),
          Text(' → ', style: mutedStyle),
        ],
        _GlowVersion(
          text: 'v$target',
          style: baseStyle.copyWith(fontWeight: FontWeight.w500),
        ),
        if (hasTheme) Text(' · $themeName', style: baseStyle),
      ],
    );
  }
}

/// The dialog title with a slow, wide sheen loop across its letters.
///
/// The sheen is a product decision outside M3. It mirrors the sheen already
/// used by the Sleep action, but wider and brighter so it reads on the large
/// title and pauses between passes.
class _ShinyTitle extends StatefulWidget {
  const _ShinyTitle({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  State<_ShinyTitle> createState() => _ShinyTitleState();
}

class _ShinyTitleState extends State<_ShinyTitle>
    with SingleTickerProviderStateMixin {
  static const _cycleDuration = Duration(milliseconds: 5000);
  static const _sweepFraction = 2.2 / 5.0;
  static const _startDelay = Duration(milliseconds: 300);
  static const _sweepCurve = Curves.easeInOutCubic;

  late final AnimationController _controller;
  late final Animation<double> _animation;
  Timer? _startTimer;
  bool _started = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _cycleDuration);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, _sweepFraction, curve: _sweepCurve),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);

    if (_reduceMotion) {
      _startTimer?.cancel();
      _startTimer = null;
      _controller
        ..stop()
        ..value = 0;
      _started = false;
      return;
    }

    if (_started) return;
    _started = true;
    _startTimer?.cancel();
    _startTimer = Timer(_startDelay, () {
      if (!mounted || _reduceMotion) return;
      _controller.repeat();
    });
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Text(widget.text, style: widget.style);
    if (_reduceMotion) return text;

    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final base = widget.style.color ?? scheme.onSurface;
    // In dark the title is already almost white, so a white band would barely
    // read. Use the lavender primary as a color sweep instead; in light the
    // dark title needs a light band.
    final highlight = theme.brightness == Brightness.dark
        ? scheme.primary
        : Color.lerp(base, Colors.white, 0.65)!;

    return AnimatedBuilder(
      animation: _animation,
      child: text,
      builder: (context, child) {
        // Each cycle sweeps for 2.2 s and then waits until the 5 s cycle
        // restarts. Start and finish just outside the text, so it reads as its
        // normal color before, between and after passes.
        final begin = -1.85 + 2.7 * _animation.value;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(begin, 0),
              end: Alignment(begin + 1, 0),
              colors: [base, base, highlight, base, base],
              stops: const [0, 0.05, 0.50, 0.95, 1],
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

/// The target version with a soft, breathing primary glow.
///
/// The glow is a product decision outside M3. It uses the primary role as a
/// halo and a small color blend so the short version string stays noticeable
/// without competing with the title sheen.
class _GlowVersion extends StatefulWidget {
  const _GlowVersion({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  State<_GlowVersion> createState() => _GlowVersionState();
}

class _GlowVersionState extends State<_GlowVersion>
    with SingleTickerProviderStateMixin {
  static const _cycleDuration = Duration(milliseconds: 3000);
  static const _startDelay = Duration(milliseconds: 300);
  static const _glowCurve = Curves.easeInOut;

  late final AnimationController _controller;
  late final Animation<double> _animation;
  Timer? _startTimer;
  bool _started = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _cycleDuration);
    _animation = CurvedAnimation(parent: _controller, curve: _glowCurve);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);

    if (_reduceMotion) {
      _startTimer?.cancel();
      _startTimer = null;
      _controller
        ..stop()
        ..value = 0;
      _started = false;
      return;
    }

    if (_started) return;
    _started = true;
    _startTimer?.cancel();
    _startTimer = Timer(_startDelay, () {
      if (!mounted || _reduceMotion) return;
      _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Text(
      widget.text,
      key: const ValueKey('update-target-version'),
      style: widget.style,
    );
    if (_reduceMotion) return text;

    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final base = widget.style.color ?? scheme.onSurfaceVariant;
    final isDark = theme.brightness == Brightness.dark;
    final peakColor = isDark
        ? Color.lerp(base, Colors.white, 0.60)!
        : Color.lerp(base, scheme.primary, 0.70)!;
    final shadowAlpha = isDark ? 0.70 : 0.55;
    final blurRadius = isDark ? 14.0 : 12.0;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final glow = _animation.value;
        return Text(
          widget.text,
          key: const ValueKey('update-target-version'),
          style: widget.style.copyWith(
            color: Color.lerp(base, peakColor, glow),
            shadows: [
              Shadow(
                color: scheme.primary.withValues(alpha: shadowAlpha * glow),
                blurRadius: blurRadius,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle});

  final String title;
  final Widget subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final dialogTheme = theme.dialogTheme;
    final appearance = dialogTheme.appearance;
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        dialogTheme.padding.left,
        dialogTheme.padding.top,
        12,
        16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: _ShinyTitle(
                    text: title,
                    style: appearance.resolveHeadline(theme),
                  ),
                ),
                const SizedBox(height: 4),
                subtitle,
                const SizedBox(height: 4),
                M3EButton.icon(
                  style: M3EButtonStyle.text,
                  size: M3EButtonSize.sm,
                  decoration: const M3EButtonDecoration(
                    padding: EdgeInsets.zero,
                    minimumSize: Size(0, 40),
                  ),
                  icon: const Icon(M3EIcons.open_in_new_outlined, size: 18),
                  label: Text(l10n.updateOpenGitHub),
                  onPressed: () =>
                      Navigator.of(context).pop(UpdatePromptAction.openRelease),
                ),
              ],
            ),
          ),
          M3EIconButton(
            icon: const Icon(M3EIcons.close),
            variant: M3EIconButtonVariant.standard,
            size: M3EIconButtonSize.md,
            tooltip: l10n.updateCloseTooltip,
            semanticLabel: l10n.updateCloseTooltip,
            onPressed: () =>
                Navigator.of(context).pop(UpdatePromptAction.snooze),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.onDontRemind, required this.onDownload});

  final VoidCallback onDontRemind;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = M3ETheme.of(context).colorScheme;
    final dontRemind = M3EButton(
      style: M3EButtonStyle.text,
      size: M3EButtonSize.sm,
      decoration: M3EButtonDecoration(
        foregroundColor: WidgetStatePropertyAll<Color?>(
          scheme.onSurfaceVariant,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 40),
      ),
      onPressed: onDontRemind,
      child: Text(l10n.updateDontRemind),
    );
    final download = M3EButton(
      style: M3EButtonStyle.filled,
      size: M3EButtonSize.sm,
      onPressed: onDownload,
      child: Text(l10n.updateDownload),
    );

    // This is the same primitive M3EDialogActions uses: a row when both fit,
    // and a trailing stack with the confirming action above the dismissive one
    // when they do not.
    return OverflowBar(
      spacing: 8,
      overflowSpacing: 4,
      alignment: MainAxisAlignment.end,
      overflowAlignment: OverflowBarAlignment.end,
      overflowDirection: VerticalDirection.up,
      children: [dontRemind, download],
    );
  }
}
