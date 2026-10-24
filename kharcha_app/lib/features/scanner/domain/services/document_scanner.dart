import 'dart:typed_data';

import 'package:kharcha_app/features/scanner/domain/entities/gray_frame.dart';
import 'package:kharcha_app/features/scanner/domain/entities/photo_detection.dart';
import 'package:kharcha_app/features/scanner/domain/entities/quad.dart';

/// Finds a document in an image and flattens it. The OpenCV version lives in
/// the data layer, so the rest of the app never imports OpenCV.
abstract interface class DocumentScanner {
  /// Looks for a document in a live preview frame. Quick and approximate.
  Future<Quad?> detectInFrame(GrayFrame frame);

  /// Looks for a document in a captured JPEG, and reports the photo's size.
  Future<PhotoDetection> detectInPhoto(Uint8List jpeg);

  /// Crops [jpeg] to [quad] and straightens it into a flat rectangle (JPEG).
  Future<Uint8List> flatten(Uint8List jpeg, Quad quad);
}
