// Generates the Sleepy3 launcher icons, the Android 12+ splash marks and the
// Flutter splash mark from the brand sources in `assets/brand/`.
//
// Run from the repository root:
//
//   dart run tool/generate_brand_assets.dart
//
// Source of truth: `assets/brand/Sleepy3-transparent.png` (the mark on a
// transparent canvas). `Sleepy3-mark.png` is generated for the in-app splash;
// the launcher mipmaps, the adaptive-icon XML and the `launch_mark.png`
// sprites for the Android 12+ system splash are generated too. Commit the
// results together with any change to the source image.
//
// Geometry:
// - Adaptive icon: 108 dp canvas. Android shows 72 dp and masks the rest, so
//   the mark is drawn at 52 dp (72% of the visible height) with 10 dp of body
//   color above and below. The 66 dp safe circle is a maximum, not a target.
// - Legacy icon: full-bleed light background with the mark at 62% of the tile.
// - Android 12+ splash icon: 288 dp canvas with the mark inside the 192 dp
//   circle (190 dp tall), plus a night variant in the lavender accent.
// - Splash mark: square canvas with the mark at 92% of its height, so the
//   Flutter widget only has to size a square.
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const _sourcePath = 'assets/brand/Sleepy3-transparent.png';
const _splashMarkPath = 'assets/brand/Sleepy3-mark.png';
const _resPath = 'android/app/src/main/res';

/// Sleepy3 light body, also the launcher icon background.
final _iconBackground = img.ColorRgba8(0xEF, 0xF4, 0xF9, 0xFF);

/// The adaptive icon canvas, and the mark height inside it. The launcher only
/// shows 72 of the 108 dp, so 52 dp leaves a 10 dp body-color margin above and
/// below. Filling the 66 dp safe circle would look zoomed in.
const _adaptiveCanvasDp = 108.0;
const _adaptiveMarkDp = 52.0;

/// Android density buckets and their scale factor.
const _densities = <String, double>{
  'mdpi': 1,
  'hdpi': 1.5,
  'xhdpi': 2,
  'xxhdpi': 3,
  'xxxhdpi': 4,
};

void main() {
  final sourceFile = File(_sourcePath);
  if (!sourceFile.existsSync()) {
    stderr.writeln('Missing brand source: $_sourcePath');
    exitCode = 1;
    return;
  }

  final source = img.decodePng(sourceFile.readAsBytesSync());
  if (source == null) {
    stderr.writeln('Could not decode $_sourcePath');
    exitCode = 1;
    return;
  }

  final bounds = _alphaBounds(source);
  final mark = img.copyCrop(
    source,
    x: bounds.x,
    y: bounds.y,
    width: bounds.width,
    height: bounds.height,
  );

  _writeSplashMark(mark);
  _writeLauncherIcons(mark);
  _writeLaunchMarks(mark);

  stdout.writeln('Brand assets written to $_splashMarkPath and $_resPath.');
}

/// A square, transparent canvas with the mark at 92% of its height.
void _writeSplashMark(img.Image mark) {
  const side = 1024;
  const markHeight = side * 0.92;
  final markWidth = markHeight * mark.width / mark.height;
  final canvas = img.Image(width: side, height: side, numChannels: 4);
  img.compositeImage(
    canvas,
    _resize(mark, markWidth, markHeight),
    dstX: ((side - markWidth) / 2).round(),
    dstY: ((side - markHeight) / 2).round(),
  );
  _writePng(_splashMarkPath, canvas);
}

void _writeLauncherIcons(img.Image mark) {
  for (final entry in _densities.entries) {
    final density = entry.key;
    final scale = entry.value;
    final directory = Directory('$_resPath/mipmap-$density')
      ..createSync(recursive: true);

    // Legacy launcher icon: full-bleed brand background with the mark inset.
    final legacySize = (48 * scale).round();
    final legacy = img.Image(
      width: legacySize,
      height: legacySize,
      numChannels: 4,
    );
    img.fill(legacy, color: _iconBackground);
    _drawMark(legacy, mark, legacySize * 0.62);
    _writePng(File('${directory.path}/ic_launcher.png').path, legacy);

    // Adaptive icon layers: 108 dp canvas, mark inset from the visible edge.
    final adaptiveSize = (_adaptiveCanvasDp * scale).round();
    final foreground = img.Image(
      width: adaptiveSize,
      height: adaptiveSize,
      numChannels: 4,
    );
    _drawMark(
      foreground,
      mark,
      adaptiveSize * _adaptiveMarkDp / _adaptiveCanvasDp,
    );
    _writePng(
      File('${directory.path}/ic_launcher_foreground.png').path,
      foreground,
    );

    // Android 13+ themed icon: a white silhouette the system tints.
    final monochrome = _colorize(foreground, 255, 255, 255);
    _writePng(
      File('${directory.path}/ic_launcher_monochrome.png').path,
      monochrome,
    );
  }

  final anydpi = Directory('$_resPath/mipmap-anydpi-v26')
    ..createSync(recursive: true);
  File('${anydpi.path}/ic_launcher.xml').writeAsStringSync('''
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />
</adaptive-icon>
''');
}

/// Android 12+ splash icon: 288 dp canvas with the mark inside the 192 dp
/// circle. The night variant uses the lavender accent from the palette.
void _writeLaunchMarks(img.Image mark) {
  for (final entry in _densities.entries) {
    final scale = entry.value;
    final size = (288 * scale).round();
    final light = img.Image(width: size, height: size, numChannels: 4);
    _drawMark(light, mark, 190 * scale);
    _writePng('$_resPath/drawable-${entry.key}/launch_mark.png', light);
    _writePng(
      '$_resPath/drawable-night-${entry.key}/launch_mark.png',
      _colorize(light, 0xC6, 0xCC, 0xF7),
    );
  }
}

/// Centers [mark] on [canvas] at [height] dp-equivalent pixels.
void _drawMark(img.Image canvas, img.Image mark, double height) {
  final width = height * mark.width / mark.height;
  img.compositeImage(
    canvas,
    _resize(mark, width, height),
    dstX: ((canvas.width - width) / 2).round(),
    dstY: ((canvas.height - height) / 2).round(),
  );
}

img.Image _resize(img.Image source, double width, double height) {
  return img.copyResize(
    source,
    width: math.max(1, width.round()),
    height: math.max(1, height.round()),
    interpolation: img.Interpolation.cubic,
  );
}

/// Replaces the color of every visible pixel, keeping the alpha channel.
img.Image _colorize(img.Image source, int red, int green, int blue) {
  final result = img.Image.from(source);
  for (final pixel in result) {
    if (pixel.a > 0) {
      pixel
        ..r = red
        ..g = green
        ..b = blue;
    }
  }
  return result;
}

/// Bounding box of every pixel that is visibly opaque.
({int x, int y, int width, int height}) _alphaBounds(img.Image image) {
  var minX = image.width;
  var minY = image.height;
  var maxX = -1;
  var maxY = -1;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (image.getPixel(x, y).a > 8) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  if (maxX == -1) {
    throw StateError('The brand source has no opaque pixels.');
  }
  return (x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1);
}

void _writePng(String path, img.Image image) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(image, level: 9));
  stdout.writeln('  $path (${image.width}x${image.height})');
}
