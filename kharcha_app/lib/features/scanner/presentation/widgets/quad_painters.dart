import 'package:flutter/material.dart';

import 'package:kharcha_app/features/scanner/domain/entities/quad.dart';

const Color _outline = Color(0xFF34D399);

Path _quadPath(Quad quad, Size size) {
  final points = quad.points;
  final path = Path()..moveTo(points.first.x * size.width, points.first.y * size.height);
  for (final p in points.skip(1)) {
    path.lineTo(p.x * size.width, p.y * size.height);
  }
  return path..close();
}

/// Draws the detected outline over the live camera preview.
class QuadOverlayPainter extends CustomPainter {
  const QuadOverlayPainter(this.quad);

  final Quad? quad;

  @override
  void paint(Canvas canvas, Size size) {
    final q = quad;
    if (q == null) return;

    final path = _quadPath(q, size);
    canvas.drawPath(path, Paint()..color = _outline.withValues(alpha: 0.16));
    canvas.drawPath(
      path,
      Paint()
        ..color = _outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
    for (final p in q.points) {
      final center = Offset(p.x * size.width, p.y * size.height);
      canvas.drawCircle(center, 7, Paint()..color = _outline);
      canvas.drawCircle(
        center,
        7,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(QuadOverlayPainter oldDelegate) => oldDelegate.quad != quad;
}

/// Dims everything outside the crop outline on the adjust screen.
class CropOverlayPainter extends CustomPainter {
  const CropOverlayPainter(this.quad);

  final Quad quad;

  @override
  void paint(Canvas canvas, Size size) {
    final outside = Path()
      ..addRect(Offset.zero & size)
      ..addPath(_quadPath(quad, size), Offset.zero)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(outside, Paint()..color = const Color(0x8C060A08));
    canvas.drawPath(
      _quadPath(quad, size),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(CropOverlayPainter oldDelegate) => oldDelegate.quad != quad;
}
