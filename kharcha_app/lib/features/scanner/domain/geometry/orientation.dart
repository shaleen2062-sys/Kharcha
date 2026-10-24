import 'package:kharcha_app/features/scanner/domain/entities/quad.dart';

/// Camera preview frames arrive in the sensor's own orientation, which on most
/// phones is turned 90 degrees from how you hold the phone. This rotates a
/// normalised point so it lines up with the upright preview on screen.
///
/// [sensorOrientation] is how many degrees clockwise the frame must be turned
/// to appear upright (0, 90, 180 or 270).
Pt rotateForSensor(Pt p, int sensorOrientation) {
  switch (sensorOrientation % 360) {
    case 90:
      return Pt(1 - p.y, p.x);
    case 180:
      return Pt(1 - p.x, 1 - p.y);
    case 270:
      return Pt(p.y, 1 - p.x);
    default:
      return p;
  }
}
