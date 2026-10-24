import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kharcha_app/core/di/core_providers.dart';
import 'package:kharcha_app/core/theme/app_colors.dart';
import 'package:kharcha_app/features/receipts/presentation/providers/receipts_providers.dart';

/// "2 receipts waiting to upload". Hidden when nothing is waiting.
class PendingUploadsBanner extends ConsumerWidget {
  const PendingUploadsBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(pendingCountProvider);
    if (count == 0) return const SizedBox.shrink();
    final online = ref.watch(isOnlineProvider).maybeWhen(data: (v) => v, orElse: () => true);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(Icons.cloud_upload_outlined, color: AppColors.primarySoftInk),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                count == 1 ? '1 receipt waiting to upload' : '$count receipts waiting to upload',
                style: TextStyle(color: AppColors.primarySoftInk, fontWeight: FontWeight.w600),
              ),
            ),
            if (online)
              TextButton(
                onPressed: () => ref.read(pendingCountProvider.notifier).sync(),
                child: const Text('Upload now'),
              ),
          ],
        ),
      ),
    );
  }
}
