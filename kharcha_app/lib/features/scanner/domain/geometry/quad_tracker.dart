import 'package:kharcha_app/features/scanner/domain/entities/quad.dart';

/// Smooths the per-frame detections so the outline does not jitter, and
/// reports when the document has held still long enough to auto-capture.
class QuadTracker {
  QuadTracker({
    this.smoothing = 0.5,
    this.stableFrames = 6,
    this.stableTolerance = 0.02,
    this.jumpThreshold = 0.15,
    this.maxMisses = 3,
  });

  /// 0 keeps the old outline, 1 jumps straight to the new one.
  final double smoothing;

  /// How many steady frames in a row count as "holding still".
  final int stableFrames;

  /// A corner moving less than this (fraction of the image) counts as steady.
  final double stableTolerance;

  /// A corner moving more than this means a different document: snap to it.
  final double jumpThreshold;

  /// Frames with no detection tolerated before the outline disappears.
  final int maxMisses;

  Quad? _current;
  int _stable = 0;
  int _misses = 0;

  Quad? get current => _current;

  bool get isStable => _current != null && _stable >= stableFrames;

  void update(Quad? detected) {
    if (detected == null) {
      _misses++;
      _stable = 0;
      if (_misses > maxMisses) _current = null;
      return;
    }
    _misses = 0;

    final previous = _current;
    if (previous == null) {
      _current = detected;
      _stable = 0;
      return;
    }

    final moved = previous.maxCornerDistance(detected);
    if (moved > jumpThreshold) {
      _current = detected;
      _stable = 0;
      return;
    }

    _current = previous.lerp(detected, smoothing);
    _stable = moved <= stableTolerance ? _stable + 1 : 0;
  }

  void reset() {
    _current = null;
    _stable = 0;
    _misses = 0;
  }
}
