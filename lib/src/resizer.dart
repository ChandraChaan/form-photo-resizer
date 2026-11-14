import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:image/image.dart' as img;

import 'preset.dart';

enum ResizeStatus {
  ok,

  /// The input could not be decoded as an image.
  unreadable,

  /// Even at the lowest JPEG quality the fixed pixel size stays above the
  /// maximum file size. The limits in the preset cannot both be met.
  cannotFit,
}

class ResizeResult {
  const ResizeResult._(
    this.status, {
    this.bytes,
    this.width,
    this.height,
    this.quality,
    this.padded = false,
  });

  const ResizeResult.failure(ResizeStatus status) : this._(status);

  const ResizeResult.success({
    required Uint8List bytes,
    required int width,
    required int height,
    required int quality,
    required bool padded,
  }) : this._(
          ResizeStatus.ok,
          bytes: bytes,
          width: width,
          height: height,
          quality: quality,
          padded: padded,
        );

  final ResizeStatus status;
  final Uint8List? bytes;
  final int? width;
  final int? height;

  /// JPEG quality that was used (1 to 100).
  final int? quality;

  /// True when the encoded image was below the minimum size and zero bytes
  /// were appended after the JPEG end marker to reach it. Decoders ignore
  /// those bytes, but the image itself is unchanged.
  final bool padded;

  bool get isOk => status == ResizeStatus.ok;
}

// A file of N bytes satisfies a limit of M KB under both the 1000 and the
// 1024 definition of KB if it is at most M*1000 bytes (maximum) and at least
// M*1024 bytes (minimum). Portals do not say which one they use.
int maxBytesFor(Preset p) => p.maxKb * 1000;
int minBytesFor(Preset p) => p.minKb * 1024;

/// Resizes [input] to satisfy [preset]. Runs on a background isolate where
/// the platform supports it.
Future<ResizeResult> resizeToPreset(Uint8List input, Preset preset) =>
    compute(_resizeMessage, _Message(input, preset));

class _Message {
  const _Message(this.input, this.preset);
  final Uint8List input;
  final Preset preset;
}

ResizeResult _resizeMessage(_Message m) => resizeToPresetSync(m.input, m.preset);

/// Synchronous version, used by tests and by [resizeToPreset].
ResizeResult resizeToPresetSync(Uint8List input, Preset preset) {
  final decoded = img.decodeImage(input);
  if (decoded == null) return const ResizeResult.failure(ResizeStatus.unreadable);

  var image = img.bakeOrientation(decoded);
  image = _flattenOnWhite(image);

  if (preset.hasExactSize) {
    image = _cropAndResize(image, preset.width!, preset.height!);
  }

  final maxBytes = maxBytesFor(preset);
  final minBytes = minBytesFor(preset);

  // Free dimensions: shrink step by step until the file can fit.
  // Fixed dimensions: a single pass, the pixel size must not change.
  while (true) {
    final fit = _bestQuality(image, maxBytes);
    if (fit != null) {
      var bytes = fit.bytes;
      var padded = false;
      if (bytes.length < minBytes) {
        final out = Uint8List(minBytes)..setRange(0, bytes.length, bytes);
        bytes = out;
        padded = true;
      }
      return ResizeResult.success(
        bytes: bytes,
        width: image.width,
        height: image.height,
        quality: fit.quality,
        padded: padded,
      );
    }
    if (preset.hasExactSize || math.min(image.width, image.height) <= 32) {
      return const ResizeResult.failure(ResizeStatus.cannotFit);
    }
    image = img.copyResize(
      image,
      width: (image.width * 0.85).round(),
      interpolation: img.Interpolation.cubic,
    );
  }
}

class _Fit {
  const _Fit(this.bytes, this.quality);
  final Uint8List bytes;
  final int quality;
}

/// Highest JPEG quality whose output is at most [maxBytes], or null if even
/// quality 1 is too large.
_Fit? _bestQuality(img.Image image, int maxBytes) {
  Uint8List encode(int q) => img.encodeJpg(image, quality: q);

  var lo = 1;
  var hi = 100;
  _Fit? best;
  while (lo <= hi) {
    final mid = (lo + hi) ~/ 2;
    final bytes = encode(mid);
    if (bytes.length <= maxBytes) {
      best = _Fit(bytes, mid);
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }
  return best;
}

img.Image _cropAndResize(img.Image src, int w, int h) {
  final targetRatio = w / h;
  final srcRatio = src.width / src.height;
  late int cropW;
  late int cropH;
  if (srcRatio > targetRatio) {
    cropH = src.height;
    cropW = (src.height * targetRatio).round();
  } else {
    cropW = src.width;
    cropH = (src.width / targetRatio).round();
  }
  final x = (src.width - cropW) ~/ 2;
  final y = (src.height - cropH) ~/ 2;
  final cropped = img.copyCrop(src, x: x, y: y, width: cropW, height: cropH);
  return img.copyResize(
    cropped,
    width: w,
    height: h,
    interpolation: img.Interpolation.cubic,
  );
}

/// JPEG has no alpha channel, so transparent PNGs would turn black. Paint
/// them on white first.
img.Image _flattenOnWhite(img.Image src) {
  if (!src.hasAlpha) return src;
  final bg = img.Image(width: src.width, height: src.height, numChannels: 3);
  img.fill(bg, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(bg, src);
  return bg;
}
