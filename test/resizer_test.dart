import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:form_photo_resizer/src/preset.dart';
import 'package:form_photo_resizer/src/resizer.dart';
import 'package:image/image.dart' as img;

/// Noisy picture so JPEG output is large and the quality search has work to do.
Uint8List noisyPng(int w, int h, {int seed = 1, bool alpha = false}) {
  final rnd = math.Random(seed);
  final image = img.Image(width: w, height: h, numChannels: alpha ? 4 : 3);
  for (final p in image) {
    p
      ..r = rnd.nextInt(256)
      ..g = rnd.nextInt(256)
      ..b = rnd.nextInt(256);
    if (alpha) p.a = 0;
  }
  return img.encodePng(image);
}

Uint8List flatPng(int w, int h) {
  final image = img.Image(width: w, height: h, numChannels: 3);
  img.fill(image, color: img.ColorRgb8(30, 90, 200));
  return img.encodePng(image);
}

void main() {
  group('exact size presets', () {
    const preset = Preset(
      name: 'p',
      minKb: 20,
      maxKb: 50,
      width: 200,
      height: 230,
    );

    test('output has exact pixels and size within limits', () {
      final r = resizeToPresetSync(noisyPng(900, 700), preset);
      expect(r.isOk, isTrue);
      final out = img.decodeJpg(r.bytes!)!;
      expect(out.width, 200);
      expect(out.height, 230);
      expect(r.bytes!.length, lessThanOrEqualTo(preset.maxKb * 1000));
      expect(r.bytes!.length, greaterThanOrEqualTo(preset.minKb * 1024));
    });

    test('portrait and landscape inputs both end at the target size', () {
      for (final (w, h) in [(300, 1200), (1200, 300), (500, 500)]) {
        final r = resizeToPresetSync(noisyPng(w, h), preset);
        final out = img.decodeJpg(r.bytes!)!;
        expect((out.width, out.height), (200, 230), reason: '$w x $h');
      }
    });

    test('flat image below the minimum is padded, still decodes', () {
      final r = resizeToPresetSync(flatPng(400, 400), preset);
      expect(r.isOk, isTrue);
      expect(r.padded, isTrue);
      expect(r.bytes!.length, preset.minKb * 1024);
      expect(img.decodeJpg(r.bytes!), isNotNull);
    });

    test('impossible limits report cannotFit instead of breaking pixels', () {
      const impossible = Preset(
        name: 'x',
        minKb: 1,
        maxKb: 1,
        width: 1000,
        height: 1000,
      );
      final r = resizeToPresetSync(noisyPng(1200, 1200), impossible);
      expect(r.status, ResizeStatus.cannotFit);
    });
  });

  group('size-only presets', () {
    const preset = Preset(name: 'p', minKb: 20, maxKb: 100);

    test('large image is shrunk under the maximum, ratio kept', () {
      final r = resizeToPresetSync(noisyPng(1600, 800), preset);
      expect(r.isOk, isTrue);
      expect(r.bytes!.length, lessThanOrEqualTo(100 * 1000));
      final out = img.decodeJpg(r.bytes!)!;
      expect((out.width / out.height), closeTo(2.0, 0.02));
    });

    test('small image already inside limits keeps its pixel size', () {
      final r = resizeToPresetSync(noisyPng(120, 90), preset);
      expect(r.isOk, isTrue);
      expect((r.width, r.height), (120, 90));
    });
  });

  test('transparent PNG becomes white, not black', () {
    const preset = Preset(
      name: 'p',
      minKb: 1,
      maxKb: 50,
      width: 64,
      height: 64,
    );
    final r = resizeToPresetSync(noisyPng(64, 64, alpha: true), preset);
    final out = img.decodeJpg(r.bytes!)!;
    final px = out.getPixel(32, 32);
    expect(px.r, greaterThan(240));
    expect(px.g, greaterThan(240));
    expect(px.b, greaterThan(240));
  });

  test('garbage bytes are reported as unreadable', () {
    final r = resizeToPresetSync(
      Uint8List.fromList([1, 2, 3, 4]),
      const Preset(name: 'p', minKb: 1, maxKb: 10),
    );
    expect(r.status, ResizeStatus.unreadable);
  });

  test('KB limits are met under both 1000 and 1024 definitions', () {
    const p = Preset(name: 'p', minKb: 10, maxKb: 20);
    expect(maxBytesFor(p), 20000);
    expect(minBytesFor(p), 10240);
  });
}
