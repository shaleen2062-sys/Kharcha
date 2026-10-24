import 'dart:math' as math;

/// A point in normalised image coordinates: x and y both run from 0 to 1,
/// measured from the top-left corner of the image.
class Pt {
  const Pt(this.x, this.y);

  final double x;
  final double y;

  double distanceTo(Pt other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  Pt lerp(Pt other, double t) => Pt(x + (other.x - x) * t, y + (other.y - y) * t);

  Pt clamped() => Pt(x.clamp(0.0, 1.0).toDouble(), y.clamp(0.0, 1.0).toDouble());

  @override
  bool operator ==(Object other) => other is Pt && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'Pt($x, $y)';
}

/// The four corners of a document, in the order top-left, top-right,
/// bottom-right, bottom-left. Pure Dart, so it is easy to unit test.
class Quad {
  const Quad({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
  });

  /// A rectangle inset from the image edges by [margin] on every side.
  factory Quad.inset([double margin = 0.08]) => Quad(
        topLeft: Pt(margin, margin),
        topRight: Pt(1 - margin, margin),
        bottomRight: Pt(1 - margin, 1 - margin),
        bottomLeft: Pt(margin, 1 - margin),
      );

  /// Orders four points into top-left, top-right, bottom-right, bottom-left.
  /// Top-left has the smallest x+y, bottom-right the largest; top-right has the
  /// smallest y-x, bottom-left the largest.
  factory Quad.fromUnordered(List<Pt> points) {
    if (points.length != 4) {
      throw ArgumentError('A quad needs exactly 4 points, got ${points.length}');
    }
    final bySum = [...points]..sort((a, b) => (a.x + a.y).compareTo(b.x + b.y));
    final byDiff = [...points]..sort((a, b) => (a.y - a.x).compareTo(b.y - b.x));
    return Quad(
      topLeft: bySum.first,
      topRight: byDiff.first,
      bottomRight: bySum.last,
      bottomLeft: byDiff.last,
    );
  }

  /// Share of the image a detected document must cover to be accepted.
  static const double minArea = 0.15;
  static const double maxArea = 0.97;

  /// A document outline always has four corners.
  static const int cornerCount = 4;

  final Pt topLeft;
  final Pt topRight;
  final Pt bottomRight;
  final Pt bottomLeft;

  List<Pt> get points => [topLeft, topRight, bottomRight, bottomLeft];

  /// Area as a fraction of the whole image (shoelace formula).
  double get area {
    final p = points;
    var sum = 0.0;
    for (var i = 0; i < 4; i++) {
      final a = p[i];
      final b = p[(i + 1) % 4];
      sum += a.x * b.y - b.x * a.y;
    }
    return sum.abs() / 2;
  }

  bool get isConvex {
    final p = points;
    var sign = 0;
    for (var i = 0; i < 4; i++) {
      final a = p[i];
      final b = p[(i + 1) % 4];
      final c = p[(i + 2) % 4];
      final cross = (b.x - a.x) * (c.y - b.y) - (b.y - a.y) * (c.x - b.x);
      if (cross == 0) return false;
      final s = cross > 0 ? 1 : -1;
      if (sign == 0) {
        sign = s;
      } else if (s != sign) {
        return false;
      }
    }
    return true;
  }

  /// A believable document: convex, a sensible size, and no collapsed sides.
  bool get isUsable {
    if (!isConvex) return false;
    final a = area;
    if (a < minArea || a > maxArea) return false;
    final p = points;
    for (var i = 0; i < 4; i++) {
      if (p[i].distanceTo(p[(i + 1) % 4]) < 0.05) return false;
    }
    return true;
  }

  Quad withCorner(int index, Pt point) {
    switch (index) {
      case 0:
        return Quad(topLeft: point, topRight: topRight, bottomRight: bottomRight, bottomLeft: bottomLeft);
      case 1:
        return Quad(topLeft: topLeft, topRight: point, bottomRight: bottomRight, bottomLeft: bottomLeft);
      case 2:
        return Quad(topLeft: topLeft, topRight: topRight, bottomRight: point, bottomLeft: bottomLeft);
      case 3:
        return Quad(topLeft: topLeft, topRight: topRight, bottomRight: bottomRight, bottomLeft: point);
      default:
        throw RangeError('Corner index must be 0 to 3, got $index');
    }
  }

  Quad map(Pt Function(Pt point) transform) => Quad(
        topLeft: transform(topLeft),
        topRight: transform(topRight),
        bottomRight: transform(bottomRight),
        bottomLeft: transform(bottomLeft),
      );

  Quad lerp(Quad other, double t) => Quad(
        topLeft: topLeft.lerp(other.topLeft, t),
        topRight: topRight.lerp(other.topRight, t),
        bottomRight: bottomRight.lerp(other.bottomRight, t),
        bottomLeft: bottomLeft.lerp(other.bottomLeft, t),
      );

  /// The largest distance any corner has moved compared with [other].
  double maxCornerDistance(Quad other) {
    final a = points;
    final b = other.points;
    var worst = 0.0;
    for (var i = 0; i < 4; i++) {
      worst = math.max(worst, a[i].distanceTo(b[i]));
    }
    return worst;
  }
}
