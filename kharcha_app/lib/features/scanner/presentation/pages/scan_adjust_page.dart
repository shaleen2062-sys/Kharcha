import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/core/router/route_names.dart';
import 'package:kharcha_app/core/theme/app_text_styles.dart';
import 'package:kharcha_app/core/widgets/app_button.dart';
import 'package:kharcha_app/core/widgets/app_snack_bar.dart';
import 'package:kharcha_app/core/widgets/loading_view.dart';
import 'package:kharcha_app/features/scanner/domain/entities/quad.dart';
import 'package:kharcha_app/features/scanner/presentation/providers/scan_session.dart';
import 'package:kharcha_app/features/scanner/presentation/widgets/quad_painters.dart';

const Color _background = Color(0xFF0E1512);
const Color _handleColor = Color(0xFF34D399);

/// Lets the user drag the four corners onto the receipt before it is flattened.
class ScanAdjustPage extends ConsumerStatefulWidget {
  const ScanAdjustPage({super.key});

  @override
  ConsumerState<ScanAdjustPage> createState() => _ScanAdjustPageState();
}

class _ScanAdjustPageState extends ConsumerState<ScanAdjustPage> {
  bool _busy = false;
  bool _leaving = false;

  Future<void> _autoDetect() async {
    setState(() => _busy = true);
    try {
      final found = await ref.read(scanSessionProvider.notifier).autoDetect();
      if (!found && mounted) {
        AppSnackBar.error(
          context,
          const UnknownFailure('Could not find the receipt edges. Drag the corners onto it.'),
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(context, const UnknownFailure('Edge detection failed. Drag the corners instead.'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    setState(() => _busy = true);
    try {
      await ref.read(scanSessionProvider.notifier).process();
      if (!mounted) return;
      await context.push(RoutePaths.scanPreview);
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(
          context,
          const UnknownFailure('Could not straighten the receipt. Try moving the corners.'),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _moveCorner(int index, Offset delta, Size size) {
    final current = ref.read(scanSessionProvider).quad;
    if (current == null) return;
    final corner = current.points[index];
    final moved = Pt(
      corner.x + delta.dx / size.width,
      corner.y + delta.dy / size.height,
    ).clamped();
    ref.read(scanSessionProvider.notifier).setQuad(current.withCorner(index, moved));
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(scanSessionProvider);

    if (!session.hasCapture) {
      // Nothing was captured (for example the app restarted on this screen).
      if (!_leaving) {
        _leaving = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go(RoutePaths.home);
        });
      }
      return const Scaffold(backgroundColor: _background, body: LoadingView());
    }

    final quad = session.quad!;
    final aspect = (session.width > 0 && session.height > 0) ? session.width / session.height : 3 / 4;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back to the camera',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF1D2A24),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(44, 44),
                    ),
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _busy ? null : () => context.pop(),
                  ),
                  const Spacer(),
                  Text('Adjust edges', style: AppTextStyles.subheading.copyWith(color: Colors.white, fontSize: 18)),
                  const Spacer(),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
              child: Text(
                session.autoDetected
                    ? 'Drag the corners to fine-tune the edges.'
                    : 'We could not find the edges. Drag the corners onto the receipt.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFB9C9C1), fontSize: 14),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    var width = constraints.maxWidth;
                    var height = width / aspect;
                    if (height > constraints.maxHeight) {
                      height = constraints.maxHeight;
                      width = height * aspect;
                    }
                    final size = Size(width, height);
                    return Center(
                      child: SizedBox(
                        width: width,
                        height: height,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: Image.memory(
                                session.original!,
                                fit: BoxFit.fill,
                                gaplessPlayback: true,
                                // Decode at screen size, not the full 12 megapixels.
                                cacheWidth: 1600,
                              ),
                            ),
                            Positioned.fill(
                              child: CustomPaint(painter: CropOverlayPainter(quad)),
                            ),
                            for (var i = 0; i < Quad.cornerCount; i++)
                              _handle(i, quad.points[i], size),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: TextButton.icon(
                onPressed: _busy ? null : _autoDetect,
                style: TextButton.styleFrom(foregroundColor: Colors.white, minimumSize: const Size(44, 44)),
                icon: const Icon(Icons.crop_free),
                label: const Text('Auto-detect again'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(
                children: [
                  AppButton(label: 'Use this photo', onPressed: _confirm, isLoading: _busy),
                  const SizedBox(height: 10),
                  Theme(
                    data: Theme.of(context).copyWith(
                      outlinedButtonTheme: OutlinedButtonThemeData(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF3B4B43)),
                        ),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _busy ? null : () => context.pop(),
                        style: OutlinedButton.styleFrom(
                          shape: const StadiumBorder(),
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF3B4B43)),
                        ),
                        child: const Text('Retake'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _handle(int index, Pt point, Size size) {
    return Positioned(
      left: point.x * size.width - 22,
      top: point.y * size.height - 22,
      width: 44,
      height: 44,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: _busy ? null : (details) => _moveCorner(index, details.delta, size),
        child: Semantics(
          label: 'Corner ${index + 1} of 4',
          child: Center(
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: _handleColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
