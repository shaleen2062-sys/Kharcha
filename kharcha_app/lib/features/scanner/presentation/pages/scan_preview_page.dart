import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kharcha_app/core/router/route_names.dart';
import 'package:kharcha_app/core/theme/app_text_styles.dart';
import 'package:kharcha_app/core/widgets/app_button.dart';
import 'package:kharcha_app/core/widgets/app_snack_bar.dart';
import 'package:kharcha_app/core/widgets/error_view.dart';
import 'package:kharcha_app/features/receipts/presentation/providers/receipts_providers.dart';
import 'package:kharcha_app/features/scanner/presentation/providers/scan_session.dart';

/// Shows the cropped, straightened receipt.
///
/// The finished JPEG is `ref.read(scanSessionProvider).processed`. The receipts
/// feature should take it from there (upload it, then clear the session).
class ScanPreviewPage extends ConsumerWidget {
  const ScanPreviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final processed = ref.watch(scanSessionProvider).processed;
    final uploading = ref.watch(uploadControllerProvider).isLoading;

    if (processed == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Receipt scan')),
        body: ErrorView(
          message: 'Nothing to show yet. Scan a receipt first.',
          onRetry: () => context.go(RoutePaths.home),
        ),
      );
    }

    final kilobytes = (processed.length / 1024).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Receipt scan')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDDE3DC)),
                ),
                clipBehavior: Clip.antiAlias,
                child: InteractiveViewer(
                  maxScale: 5,
                  child: Center(child: Image.memory(processed, fit: BoxFit.contain, gaplessPlayback: true)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Text(
                'Straightened receipt, $kilobytes KB. Pinch to zoom.',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Column(
                children: [
                  AppButton(
                    label: 'Upload receipt',
                    isLoading: uploading,
                    onPressed: () async {
                      final outcome = await ref.read(uploadControllerProvider.notifier).upload(processed);
                      if (!context.mounted) return;
                      if (outcome != UploadOutcome.failed) {
                        ref.read(scanSessionProvider.notifier).clear();
                        if (outcome == UploadOutcome.queued) {
                          AppSnackBar.success(context, 'Saved. It will upload when you are back online.');
                        }
                        context.go(RoutePaths.receipts);
                      } else {
                        // The scan stays in memory, so the user can just tap again.
                        final error = ref.read(uploadControllerProvider).error;
                        AppSnackBar.error(context, error ?? 'Upload failed.');
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    label: 'Adjust again',
                    variant: AppButtonVariant.outlined,
                    onPressed: uploading ? null : () => context.pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
