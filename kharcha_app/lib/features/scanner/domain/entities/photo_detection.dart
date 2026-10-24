import 'package:kharcha_app/features/scanner/domain/entities/quad.dart';

/// What was found in a captured photo. [quad] is null when no document outline
/// could be found; [width] and [height] are the photo's size in pixels after
/// the camera's rotation has been applied.
class PhotoDetection {
  const PhotoDetection({required this.quad, required this.width, required this.height});

  final Quad? quad;
  final int width;
  final int height;
}
