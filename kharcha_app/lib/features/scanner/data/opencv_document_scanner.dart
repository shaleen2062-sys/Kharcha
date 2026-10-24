import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:opencv_dart/opencv_dart.dart' as cv;

import 'package:kharcha_app/features/scanner/domain/entities/gray_frame.dart';
import 'package:kharcha_app/features/scanner/domain/entities/photo_detection.dart';
import 'package:kharcha_app/features/scanner/domain/entities/quad.dart';
import 'package:kharcha_app/features/scanner/domain/services/document_scanner.dart';

/// Document detection with plain OpenCV image processing. There is no AI model
/// here: it blurs the image, finds edges, and looks for the largest
/// four-sided shape. Every call runs in a background isolate so the camera
/// preview never stutters.
class OpenCvDocumentScanner implements DocumentScanner {
  OpenCvDocumentScanner();

  @override
  Future<Quad?> detectInFrame(GrayFrame frame) {
    final pixels = frame.pixels;
    final width = frame.width;
    final height = frame.height;
    return Isolate.run(() => _detectInGray(pixels, width, height));
  }

  @override
  Future<PhotoDetection> detectInPhoto(Uint8List jpeg) {
    return Isolate.run(() => _detectInJpeg(jpeg));
  }

  @override
  Future<Uint8List> flatten(Uint8List jpeg, Quad quad) {
    return Isolate.run(() => _flatten(jpeg, quad));
  }
}

/// Photos are shrunk to this many pixels on the long side before detection.
const int _analysisSize = 640;

/// The flattened receipt is capped at this many pixels on the long side.
const int _maxOutputSize = 2200;

Quad? _detectInGray(Uint8List pixels, int width, int height) {
  final gray = cv.Mat.fromList(height, width, cv.MatType.CV_8UC1, pixels);
  try {
    return _findDocument(gray);
  } finally {
    gray.dispose();
  }
}

PhotoDetection _detectInJpeg(Uint8List bytes) {
  final image = cv.imdecode(bytes, cv.IMREAD_COLOR);
  if (image.rows == 0 || image.cols == 0) {
    image.dispose();
    throw StateError('Could not read the photo.');
  }

  final width = image.cols;
  final height = image.rows;
  final longest = math.max(width, height);
  final scale = longest > _analysisSize ? _analysisSize / longest : 1.0;

  final small = scale < 1.0
      ? cv.resize(
          image,
          ((width * scale).round(), (height * scale).round()),
          interpolation: cv.INTER_AREA,
        )
      : image;
  final gray = cv.cvtColor(small, cv.COLOR_BGR2GRAY);

  try {
    return PhotoDetection(quad: _findDocument(gray), width: width, height: height);
  } finally {
    gray.dispose();
    if (!identical(small, image)) small.dispose();
    image.dispose();
  }
}

/// The detection itself. [gray] is a single-channel image of any size.
/// Returns corners as fractions of the image, so the result does not depend on
/// the size the detection ran at.
Quad? _findDocument(cv.Mat gray) {
  final width = gray.cols;
  final height = gray.rows;
  final minArea = width * height * 0.12;

  final blurred = cv.gaussianBlur(gray, (5, 5), 0);
  final edges = cv.canny(blurred, 50, 150);
  final kernel = cv.getStructuringElement(cv.MORPH_RECT, (3, 3));
  // Thickening the edges closes small gaps so the receipt outline is one shape.
  final thick = cv.dilate(edges, kernel);
  final (contours, hierarchy) = cv.findContours(
    thick,
    cv.RETR_EXTERNAL,
    cv.CHAIN_APPROX_SIMPLE,
  );

  Quad? best;
  var bestArea = 0.0;
  try {
    for (var i = 0; i < contours.length; i++) {
      final contour = contours[i];
      final area = cv.contourArea(contour);
      if (area < minArea || area <= bestArea) continue;

      final perimeter = cv.arcLength(contour, true);
      // Try a few tolerances: a crumpled edge needs a looser fit to become 4 corners.
      for (final factor in const [0.02, 0.03, 0.05]) {
        final approx = cv.approxPolyDP(contour, perimeter * factor, true);
        Quad? candidate;
        if (approx.length == 4) {
          candidate = Quad.fromUnordered([
            for (var k = 0; k < 4; k++) Pt(approx[k].x / width, approx[k].y / height),
          ]);
        }
        approx.dispose();
        if (candidate != null && candidate.isUsable) {
          best = candidate;
          bestArea = area;
          break;
        }
      }
    }
  } finally {
    blurred.dispose();
    edges.dispose();
    kernel.dispose();
    thick.dispose();
    contours.dispose();
    hierarchy.dispose();
  }
  return best;
}

/// Crops to [quad] and straightens the receipt into a flat rectangle.
Uint8List _flatten(Uint8List bytes, Quad quad) {
  final image = cv.imdecode(bytes, cv.IMREAD_COLOR);
  if (image.rows == 0 || image.cols == 0) {
    image.dispose();
    throw StateError('Could not read the photo.');
  }

  final w = image.cols.toDouble();
  final h = image.rows.toDouble();
  final tl = Pt(quad.topLeft.x * w, quad.topLeft.y * h);
  final tr = Pt(quad.topRight.x * w, quad.topRight.y * h);
  final br = Pt(quad.bottomRight.x * w, quad.bottomRight.y * h);
  final bl = Pt(quad.bottomLeft.x * w, quad.bottomLeft.y * h);

  // Output size: the longer of each pair of opposite sides.
  var outW = math.max(tl.distanceTo(tr), bl.distanceTo(br));
  var outH = math.max(tl.distanceTo(bl), tr.distanceTo(br));
  final longest = math.max(outW, outH);
  if (longest > _maxOutputSize) {
    final shrink = _maxOutputSize / longest;
    outW *= shrink;
    outH *= shrink;
  }
  final width = math.max(outW.round(), 1);
  final height = math.max(outH.round(), 1);

  final src = cv.VecPoint2f.fromList([
    cv.Point2f(tl.x, tl.y),
    cv.Point2f(tr.x, tr.y),
    cv.Point2f(br.x, br.y),
    cv.Point2f(bl.x, bl.y),
  ]);
  final dst = cv.VecPoint2f.fromList([
    cv.Point2f(0, 0),
    cv.Point2f(width - 1.0, 0),
    cv.Point2f(width - 1.0, height - 1.0),
    cv.Point2f(0, height - 1.0),
  ]);

  final matrix = cv.getPerspectiveTransform2f(src, dst);
  final flat = cv.warpPerspective(image, matrix, (width, height));
  final (ok, encoded) = cv.imencode('.jpg', flat);
  final result = Uint8List.fromList(encoded);

  flat.dispose();
  matrix.dispose();
  image.dispose();

  if (!ok) throw StateError('Could not save the flattened receipt.');
  return result;
}
