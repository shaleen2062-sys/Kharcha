import 'dart:typed_data';

/// A small greyscale copy of a camera preview frame, one byte per pixel.
class GrayFrame {
  const GrayFrame(this.pixels, this.width, this.height);

  final Uint8List pixels;
  final int width;
  final int height;
}
