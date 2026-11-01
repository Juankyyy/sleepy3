import 'package:material_ui/material_ui.dart';

import '../core/theme/sleepy3_theme.dart';

/// Plays the brand mark once over the shell when the app starts.
///
/// The native launch background and this splash share the same body color, and
/// the Android 12+ splash icon is the same mark at 190 dp, so the handoff from
/// Android to the first Flutter frame has no black gap or size jump. The intro
/// waits until the first frame is actually on screen, then zooms the mark out
/// and fades the overlay over the already-built shell.
///
/// The intervals use the M3 Expressive web fallbacks for the spatial and
/// effects springs. A splash has no gesture to interrupt, so a spring
/// simulation would not add behavior. Reduce-motion users skip the splash.
class SplashGate extends StatefulWidget {
  const SplashGate({
    super.key,
    required this.child,
    this.onFinished,
    this.startSignal,
  });

  /// The content revealed when the splash finishes.
  final Widget child;

  /// Runs once the splash is gone, or right after the first frame when
  /// reduce-motion skips it. Startup work that can block frames belongs here,
  /// not in a post-frame callback under the splash.
  final VoidCallback? onFinished;

  /// Completes when the intro may start.
  ///
  /// Defaults to the engine's first-frame-rasterized future: in debug builds
  /// the native splash can stay up while the first frame is still being
  /// rasterized, and starting earlier would finish the animation off screen.
  /// Tests have no rasterizer and pass an already-completed future.
  final Future<void>? startSignal;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate>
    with SingleTickerProviderStateMixin {
  static const _markAsset = 'assets/brand/Sleepy3-mark.png';
  static const _markSize = 144.0;
  static const _cacheWidth = 512;
  static const _duration = Duration(milliseconds: 1000);

  late final AnimationController _controller;
  late final Animation<double> _zoom;
  late final Animation<double> _exitOpacity;
  late final Animation<double> _exitZoom;

  var _visible = true;
  var _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);

    // 550 ms of zoom-out, a short hold, then a 250 ms fade. The 1.43 start
    // makes the visible mark 190 dp, the same size as the native splash icon.
    _zoom = Tween<double>(begin: 1.43, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.55, curve: Cubic(0.38, 1.21, 0.22, 1)),
      ),
    );
    _exitOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.75, 1, curve: Cubic(0.34, 0.80, 0.34, 1)),
      ),
    );
    _exitZoom = Tween<double>(begin: 1, end: 0.94).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.75, 1, curve: Cubic(0.38, 1.21, 0.22, 1)),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _visible = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onFinished?.call();
      });
      return;
    }

    precacheImage(
      const ResizeImage(AssetImage(_markAsset), width: _cacheWidth),
      context,
      onError: (error, stackTrace) {
        debugPrint('Sleepy3: could not load the splash mark: $error');
      },
    );

    final signal =
        widget.startSignal ??
        WidgetsBinding.instance.waitUntilFirstFrameRasterized;
    signal.then((_) {
      if (!mounted) return;
      _controller.forward().whenComplete(_finish);
    });
  }

  void _finish() {
    if (!mounted) return;
    setState(() => _visible = false);
    widget.onFinished?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? Sleepy3Theme.darkBackground
        : Sleepy3Theme.lightBackground;

    Widget mark = Image(
      image: const ResizeImage(AssetImage(_markAsset), width: _cacheWidth),
      width: _markSize,
      height: _markSize,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
    if (isDark) {
      // The source mark is indigo. On the dark body it takes the lavender
      // accent from the same palette, so it keeps its shape without glare.
      mark = ColorFiltered(
        colorFilter: const ColorFilter.mode(
          Sleepy3Theme.darkPrimary,
          BlendMode.srcIn,
        ),
        child: mark,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_visible)
          AbsorbPointer(
            key: const Key('sleepy3-splash'),
            child: ExcludeSemantics(
              child: AnimatedBuilder(
                animation: _controller,
                child: mark,
                builder: (context, child) {
                  return Opacity(
                    opacity: _exitOpacity.value,
                    child: ColoredBox(
                      color: background,
                      child: Center(
                        child: Transform.scale(
                          scale: _zoom.value * _exitZoom.value,
                          child: child,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
