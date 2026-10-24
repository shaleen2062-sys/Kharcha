import 'dart:typed_data';

import 'package:kharcha_app/features/scanner/domain/entities/gray_frame.dart';

/// Turns camera frames into small greyscale images for edge detection.
/// Shrinking by [step] keeps detection fast enough to run several times a second.

/// Android gives YUV frames, and the first plane (Y) is already greyscale.
/// [rowStride] is the plane's bytes per row, which can be wider than [width].
GrayFrame grayFromYPlane({
  required Uint8List yPlane,
  required int width,
  required int height,
  required int rowStride,
  int step = 2,
}) {
  final outWidth = width ~/ step;
  final outHeight = height ~/ step;
  final out = Uint8List(outWidth * outHeight);
  var o = 0;
  for (var y = 0; y < outHeight; y++) {
    final rowStart = y * step * rowStride;
    for (var x = 0; x < outWidth; x++) {
      out[o++] = yPlane[rowStart + x * step];
    }
  }
  return GrayFrame(out, outWidth, outHeight);
}

/// iOS gives BGRA frames (4 bytes per pixel). Converts to luma with integer maths.
GrayFrame grayFromBgra({
  required Uint8List bytes,
  required int width,
  required int height,
  required int rowStride,
  int step = 2,
}) {
  final outWidth = width ~/ step;
  final outHeight = height ~/ step;
  final out = Uint8List(outWidth * outHeight);
  var o = 0;
  for (var y = 0; y < outHeight; y++) {
    final rowStart = y * step * rowStride;
    for (var x = 0; x < outWidth; x++) {
      final i = rowStart + x * step * 4;
      final b = bytes[i];
      final g = bytes[i + 1];
      final r = bytes[i + 2];
      out[o++] = (29 * b + 150 * g + 77 * r) >> 8;
    }
  }
  return GrayFrame(out, outWidth, outHeight);
}
