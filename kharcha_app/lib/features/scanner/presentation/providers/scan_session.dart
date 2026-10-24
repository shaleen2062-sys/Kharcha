import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kharcha_app/features/scanner/di/scanner_di.dart';
import 'package:kharcha_app/features/scanner/domain/entities/quad.dart';

/// Everything about the receipt currently being scanned, shared by the
/// scan, adjust and preview screens.
class ScanSession {
  const ScanSession({
    this.original,
    this.width = 0,
    this.height = 0,
    this.quad,
    this.autoDetected = false,
    this.processed,
  });

  /// The photo as captured (JPEG).
  final Uint8List? original;
  final int width;
  final int height;

  /// The corners the user is adjusting, as fractions of the photo.
  final Quad? quad;

  /// False when no outline was found and the corners are just a default guess.
  final bool autoDetected;

  /// The cropped, straightened receipt (JPEG), ready to upload.
  final Uint8List? processed;

  bool get hasCapture => original != null && quad != null;

  ScanSession copyWith({
    Quad? quad,
    bool? autoDetected,
    Uint8List? processed,
    bool clearProcessed = false,
  }) {
    return ScanSession(
      original: original,
      width: width,
      height: height,
      quad: quad ?? this.quad,
      autoDetected: autoDetected ?? this.autoDetected,
      processed: clearProcessed ? null : (processed ?? this.processed),
    );
  }
}

class ScanSessionController extends Notifier<ScanSession> {
  @override
  ScanSession build() => const ScanSession();

  void setCapture({
    required Uint8List original,
    required int width,
    required int height,
    required Quad? detected,
  }) {
    state = ScanSession(
      original: original,
      width: width,
      height: height,
      quad: detected ?? Quad.inset(),
      autoDetected: detected != null,
    );
  }

  void setQuad(Quad quad) {
    state = state.copyWith(quad: quad, clearProcessed: true);
  }

  /// Runs detection again on the captured photo. Returns false if nothing was found.
  Future<bool> autoDetect() async {
    final original = state.original;
    if (original == null) return false;
    final result = await ref.read(documentScannerProvider).detectInPhoto(original);
    final found = result.quad;
    if (found == null) return false;
    state = state.copyWith(quad: found, autoDetected: true, clearProcessed: true);
    return true;
  }

  /// Crops and straightens the photo using the current corners.
  Future<void> process() async {
    final original = state.original;
    final quad = state.quad;
    if (original == null || quad == null) return;
    final flat = await ref.read(documentScannerProvider).flatten(original, quad);
    state = state.copyWith(processed: flat);
  }

  void clear() => state = const ScanSession();
}

final scanSessionProvider = NotifierProvider<ScanSessionController, ScanSession>(
  ScanSessionController.new,
);
