import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('the adaptive foreground leaves a body-color margin around the mark', () {
    final file = File(
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png',
    );
    final image = img.decodePng(file.readAsBytesSync());
    expect(
      image,
      isNotNull,
      reason: 'Run dart run tool/generate_brand_assets.dart.',
    );

    final bounds = _opaqueBounds(image!);

    // The mark is drawn at 52 dp of the 108 dp canvas. The launcher shows only
    // 72 dp, so the mark fills 72% of the tile. Reaching the 66 dp safe circle
    // (91.7% of the tile) is what made the icon look zoomed in.
    expect(bounds.height / image.height, closeTo(52 / 108, 0.005));
    expect(
      (bounds.y - (image.height - bounds.height) / 2).abs(),
      lessThanOrEqualTo(1),
      reason: 'the mark is centered vertically',
    );
    expect(
      (bounds.x - (image.width - bounds.width) / 2).abs(),
      lessThanOrEqualTo(1),
      reason: 'the mark is centered horizontally',
    );
  });

  test('the notification mark leaves room for the circular background', () {
    final file = File(
      'android/app/src/main/res/drawable-xxxhdpi/ic_notification_mark.png',
    );
    final image = img.decodePng(file.readAsBytesSync());
    expect(
      image,
      isNotNull,
      reason: 'Run dart run tool/generate_brand_assets.dart.',
    );

    final bounds = _opaqueBounds(image!);

    expect(bounds.height / image.height, closeTo(32 / 40, 0.005));
    expect(
      (bounds.y - (image.height - bounds.height) / 2).abs(),
      lessThanOrEqualTo(1),
      reason: 'the mark is centered vertically',
    );
    expect(
      (bounds.x - (image.width - bounds.width) / 2).abs(),
      lessThanOrEqualTo(1),
      reason: 'the mark is centered horizontally',
    );
  });
}

({int x, int y, int width, int height}) _opaqueBounds(img.Image image) {
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
    throw StateError('The adaptive foreground has no opaque pixels.');
  }
  return (x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1);
}
