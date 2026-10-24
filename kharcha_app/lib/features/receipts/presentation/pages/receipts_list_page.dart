import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kharcha_app/core/widgets/screen_header.dart';
import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/core/router/route_names.dart';
import 'package:kharcha_app/core/theme/app_colors.dart';
import 'package:kharcha_app/core/theme/app_text_styles.dart';
import 'package:kharcha_app/core/widgets/empty_state.dart';
import 'package:kharcha_app/core/widgets/error_view.dart';
import 'package:kharcha_app/core/widgets/loading_view.dart';
import 'package:kharcha_app/core/widgets/offline_banner.dart';
import 'package:kharcha_app/features/receipts/domain/entities/receipt.dart';
import 'package:kharcha_app/features/receipts/presentation/providers/receipts_providers.dart';
import 'package:kharcha_app/features/receipts/presentation/widgets/pending_uploads_banner.dart';
import 'package:kharcha_app/features/receipts/presentation/widgets/money.dart';
import 'package:kharcha_app/features/receipts/presentation/widgets/receipt_image.dart';
import 'package:kharcha_app/features/receipts/presentation/widgets/status_chip.dart';

class ReceiptsPage extends ConsumerWidget {
  const ReceiptsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipts = ref.watch(receiptsProvider);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 64,
        leading: const Padding(padding: EdgeInsets.only(left: 20), child: CircleBackButton()),
        title: const Text('My receipts'),
      ),
      floatingActionButton: kIsWeb
          ? null // no camera on web
          : FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.scan),
        icon: const Icon(Icons.photo_camera_outlined),
        label: const Text('Scan receipt'),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          const Padding(padding: EdgeInsets.fromLTRB(16, 8, 16, 0), child: PendingUploadsBanner()),
          Expanded(
            child: receipts.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(
                message: error is Failure ? error.message : 'Could not load your receipts.',
                onRetry: () => ref.invalidate(receiptsProvider),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No receipts yet',
                    message: 'Tap Scan receipt to add your first one.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(receiptsProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _ReceiptTile(receipt: list[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptTile extends StatelessWidget {
  const _ReceiptTile({required this.receipt});

  final Receipt receipt;

  @override
  Widget build(BuildContext context) {
    final subtitle = formatDate(receipt.date);
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push(RoutePaths.receiptDetailFor(receipt.id)),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              // The photo: tap it to see it full screen, tap the rest of the row for the details.
              Semantics(
                button: true,
                label: 'View photo',
                child: GestureDetector(
                  onTap: () => context.push(RoutePaths.receiptPhotoFor(receipt.id)),
                  child: SizedBox(
                    width: 56,
                    height: 72,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ReceiptImage(receipt: receipt),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(receipt.title, style: AppTextStyles.subheading, maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTextStyles.caption),
                    ],
                    const SizedBox(height: 8),
                    StatusChip(receipt.status),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(formatMoney(receipt.total, receipt.currency), style: AppTextStyles.body),
            ],
          ),
        ),
      ),
    );
  }
}
