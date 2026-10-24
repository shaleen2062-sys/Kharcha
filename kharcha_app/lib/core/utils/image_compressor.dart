/// Receipt photos are shrunk before upload so they send fast on mobile data.
/// Pass these to ImagePicker.pickImage(...) or the camera capture.
abstract final class ImageCompressor {
  static const double maxWidth = 1800;
  static const double maxHeight = 2600;
  static const int jpegQuality = 85;
}
