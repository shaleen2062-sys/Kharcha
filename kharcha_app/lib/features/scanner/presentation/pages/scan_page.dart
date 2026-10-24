import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/core/router/route_names.dart';
import 'package:kharcha_app/core/theme/app_colors.dart';
import 'package:kharcha_app/core/theme/app_text_styles.dart';
import 'package:kharcha_app/core/widgets/app_snack_bar.dart';
import 'package:kharcha_app/core/widgets/error_view.dart';
import 'package:kharcha_app/core/widgets/offline_banner.dart';
import 'package:kharcha_app/features/scanner/data/frame_converter.dart';
import 'package:kharcha_app/features/scanner/di/scanner_di.dart';
import 'package:kharcha_app/features/scanner/domain/entities/gray_frame.dart';
import 'package:kharcha_app/features/scanner/domain/entities/quad.dart';
import 'package:kharcha_app/features/scanner/domain/geometry/orientation.dart';
import 'package:kharcha_app/features/scanner/domain/geometry/quad_tracker.dart';
import 'package:kharcha_app/features/scanner/presentation/providers/scan_session.dart';
import 'package:kharcha_app/features/scanner/presentation/widgets/quad_painters.dart';

const Color _background = Color(0xFF0E1512);
const Color _panel = Color(0xFF1D2A24);

/// Live camera with the detected receipt outlined, like a document scanner.
class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> with WidgetsBindingObserver {
  /// Normally null: the rotation is read from the camera. If the outline looks
  /// turned or flipped on your phone, set this to 0, 90, 180 or 270.
  static const int? _rotationOverride = null;

  /// How often a preview frame is analysed.
  static const Duration _frameInterval = Duration(milliseconds: 200);

  final QuadTracker _tracker = QuadTracker();

  CameraController? _controller;
  String? _error;
  Quad? _quad;
  bool _starting = false;
  bool _streaming = false;
  bool _analysing = false;
  bool _capturing = false;
  bool _autoCapture = true;
  bool _torch = false;
  DateTime _lastFrame = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    _startCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      final controller = _controller;
      if (controller == null) return;
      _controller = null;
      _streaming = false;
      if (mounted) setState(() {});
      controller.dispose();
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      _startCamera();
    }
  }

  // ---- camera ------------------------------------------------------------

  Future<void> _startCamera() async {
    if (_starting) return;
    _starting = true;
    if (mounted) setState(() => _error = null);
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showError('No camera found on this device.');
        return;
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.iOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.yuv420,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _controller = controller;
      _torch = false;
      await _startStream();
      if (mounted) setState(() {});
    } on CameraException catch (e) {
      _showError(_cameraMessage(e));
    } catch (_) {
      _showError('Could not start the camera.');
    } finally {
      _starting = false;
    }
  }

  String _cameraMessage(CameraException e) {
    if (e.code.startsWith('CameraAccessDenied')) {
      return 'Camera permission is off. Allow camera access for Kharcha in your phone settings, then try again.';
    }
    if (e.code.startsWith('CameraAccessRestricted')) {
      return 'Camera access is restricted on this device.';
    }
    return 'Could not start the camera.';
  }

  void _showError(String message) {
    if (mounted) setState(() => _error = message);
  }

  Future<void> _startStream() async {
    final controller = _controller;
    if (controller == null || _streaming || !controller.value.isInitialized) return;
    await controller.startImageStream(_onFrame);
    _streaming = true;
  }

  Future<void> _stopStream() async {
    final controller = _controller;
    if (controller == null || !_streaming) return;
    _streaming = false;
    try {
      await controller.stopImageStream();
    } catch (_) {
      // Already stopped.
    }
  }

  Future<void> _resumePreview() async {
    if (!mounted) return;
    try {
      await _startStream();
    } catch (_) {
      // The next lifecycle change will try again.
    }
  }

  Future<void> _toggleTorch() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final next = !_torch;
    try {
      await controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() => _torch = next);
    } catch (_) {
      if (mounted) AppSnackBar.error(context, const UnknownFailure('This camera has no flash.'));
    }
  }

  // ---- live detection ----------------------------------------------------

  void _onFrame(CameraImage image) {
    if (_analysing || _capturing) return;
    final now = DateTime.now();
    if (now.difference(_lastFrame) < _frameInterval) return;
    _lastFrame = now;

    final GrayFrame gray;
    try {
      gray = _toGray(image);
    } catch (_) {
      return;
    }
    _analysing = true;
    final rotation = _rotationOverride ?? _controller?.description.sensorOrientation ?? 0;
    _analyse(gray, rotation);
  }

  GrayFrame _toGray(CameraImage image) {
    final plane = image.planes.first;
    if (image.format.group == ImageFormatGroup.bgra8888) {
      return grayFromBgra(
        bytes: plane.bytes,
        width: image.width,
        height: image.height,
        rowStride: plane.bytesPerRow,
      );
    }
    return grayFromYPlane(
      yPlane: plane.bytes,
      width: image.width,
      height: image.height,
      rowStride: plane.bytesPerRow,
    );
  }

  Future<void> _analyse(GrayFrame gray, int rotation) async {
    try {
      final found = await ref.read(documentScannerProvider).detectInFrame(gray);
      if (!mounted) return;

      Quad? upright;
      if (found != null) {
        // Rotating changes which corner is "top-left", so put them back in order.
        upright = Quad.fromUnordered([
          for (final p in found.points) rotateForSensor(p, rotation),
        ]);
      }
      _tracker.update(upright);
      setState(() => _quad = _tracker.current);

      if (_autoCapture && _tracker.isStable) await _capture();
    } catch (_) {
      // A frame that fails is skipped.
    } finally {
      _analysing = false;
    }
  }

  // ---- capture -----------------------------------------------------------

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _capturing || !controller.value.isInitialized) return;
    _capturing = true;
    try {
      await _stopStream();
      final file = await controller.takePicture();
      await _openAdjust(await file.readAsBytes());
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(context, const UnknownFailure('Could not take the photo. Please try again.'));
      }
      await _resumePreview();
    } finally {
      _capturing = false;
    }
  }

  Future<void> _pickFromGallery() async {
    if (_capturing) return;
    _capturing = true;
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      await _stopStream();
      await _openAdjust(await picked.readAsBytes());
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(context, const UnknownFailure('Could not open that photo. Please try another.'));
      }
      await _resumePreview();
    } finally {
      _capturing = false;
    }
  }

  /// Finds the receipt in the photo, stores it for the next screens, and opens
  /// the adjust screen. Restarts the live preview when the user comes back.
  Future<void> _openAdjust(Uint8List bytes) async {
    final result = await ref.read(documentScannerProvider).detectInPhoto(bytes);
    if (!mounted) return;
    ref.read(scanSessionProvider.notifier).setCapture(
          original: bytes,
          width: result.width,
          height: result.height,
          detected: result.quad,
        );
    _tracker.reset();
    setState(() => _quad = null);
    await context.push(RoutePaths.scanAdjust);
    await _resumePreview();
  }

  // ---- ui ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              torchOn: _torch,
              onClose: () => context.go(RoutePaths.home),
              onTorch: _toggleTorch,
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: OfflineBanner(
                message: 'You are offline. You can still scan, but uploading needs a connection.',
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _buildPreview(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: _HintChip(found: _quad != null, steady: _tracker.isStable),
            ),
            _Controls(
              autoCapture: _autoCapture,
              onGallery: _pickFromGallery,
              onShutter: _capture,
              onToggleAuto: () => setState(() => _autoCapture = !_autoCapture),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (_error != null) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
        ),
        child: ErrorView(message: _error!, onRetry: _startCamera),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: ColoredBox(
        color: const Color(0xFF17211C),
        child: Center(
          child: AspectRatio(
            // The sensor reports landscape; the phone is held upright.
            aspectRatio: 1 / controller.value.aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(controller),
                CustomPaint(painter: QuadOverlayPainter(_quad)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.torchOn, required this.onClose, required this.onTorch});

  final bool torchOn;
  final VoidCallback onClose;
  final VoidCallback onTorch;

  @override
  Widget build(BuildContext context) {
    final style = IconButton.styleFrom(
      backgroundColor: _panel,
      foregroundColor: Colors.white,
      minimumSize: const Size(44, 44),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            tooltip: 'Close scanner',
            style: style,
            icon: const Icon(Icons.close),
            onPressed: onClose,
          ),
          Text('Scan receipt', style: AppTextStyles.subheading.copyWith(color: Colors.white, fontSize: 18)),
          IconButton(
            tooltip: torchOn ? 'Turn flash off' : 'Turn flash on',
            style: style,
            icon: Icon(torchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: onTorch,
          ),
        ],
      ),
    );
  }
}

class _HintChip extends StatelessWidget {
  const _HintChip({required this.found, required this.steady});

  final bool found;
  final bool steady;

  @override
  Widget build(BuildContext context) {
    final String text;
    if (!found) {
      text = 'Point the camera at a receipt';
    } else if (steady) {
      text = 'Capturing, hold steady';
    } else {
      text = 'Receipt found, hold steady';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: found ? AppColors.primary : _panel,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (found) ...[
            const Icon(Icons.check, size: 18, color: Colors.white),
            const SizedBox(width: 8),
          ],
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.autoCapture,
    required this.onGallery,
    required this.onShutter,
    required this.onToggleAuto,
  });

  final bool autoCapture;
  final VoidCallback onGallery;
  final VoidCallback onShutter;
  final VoidCallback onToggleAuto;

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(color: Color(0xFFB9C9C1), fontSize: 12);
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 18, 36, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 68,
            child: Column(
              children: [
                IconButton(
                  tooltip: 'Choose from gallery',
                  style: IconButton.styleFrom(
                    backgroundColor: _panel,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(52, 52),
                  ),
                  icon: const Icon(Icons.photo_library_outlined),
                  onPressed: onGallery,
                ),
                const SizedBox(height: 6),
                const Text('Gallery', style: labelStyle),
              ],
            ),
          ),
          Column(
            children: [
              Semantics(
                button: true,
                label: 'Take photo',
                child: GestureDetector(
                  onTap: onShutter,
                  child: Container(
                    width: 76,
                    height: 76,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text('Capture', style: labelStyle),
            ],
          ),
          SizedBox(
            width: 68,
            child: Column(
              children: [
                IconButton(
                  tooltip: autoCapture ? 'Auto capture is on' : 'Auto capture is off',
                  style: IconButton.styleFrom(
                    backgroundColor: autoCapture ? AppColors.primary : _panel,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(52, 52),
                  ),
                  icon: const Icon(Icons.center_focus_strong_outlined),
                  onPressed: onToggleAuto,
                ),
                const SizedBox(height: 6),
                Text(autoCapture ? 'Auto: on' : 'Auto: off', style: labelStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
