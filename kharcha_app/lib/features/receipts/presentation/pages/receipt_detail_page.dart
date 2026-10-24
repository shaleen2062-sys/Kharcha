import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kharcha_app/core/widgets/screen_header.dart';
import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/core/router/route_names.dart';
import 'package:kharcha_app/core/theme/app_colors.dart';
import 'package:kharcha_app/core/theme/app_text_styles.dart';
import 'package:kharcha_app/core/widgets/app_button.dart';
import 'package:kharcha_app/core/widgets/error_view.dart';
import 'package:kharcha_app/core/widgets/loading_view.dart';
import 'package:kharcha_app/features/receipts/domain/entities/receipt.dart';
import 'package:kharcha_app/features/receipts/presentation/providers/receipts_providers.dart';
import 'package:kharcha_app/features/receipts/presentation/widgets/money.dart';
import 'package:kharcha_app/features/receipts/presentation/widgets/receipt_image.dart';
import 'package:kharcha_app/features/receipts/presentation/widgets/status_chip.dart';

/// One receipt: header, line items, and the original photo.
/// While the backend is still reading it, the page re-checks every 4 seconds.
class ReceiptDetailPage extends ConsumerStatefulWidget {
  const ReceiptDetailPage({super.key, required this.id});

  final String id;

  @override
  ConsumerState<ReceiptDetailPage> createState() => _ReceiptDetailPageState();
}

class _ReceiptDetailPageState extends ConsumerState<ReceiptDetailPage> {
  bool _polling = false;

  Future<void> _poll() async {
    if (_polling) return;
    _polling = true;
    await Future<void>.delayed(const Duration(seconds: 4));
    _polling = false;
    if (mounted) ref.invalidate(receiptProvider(widget.id));
  }

  @override
  Widget build(BuildContext context) {
    final receipt = ref.watch(receiptProvider(widget.id));

    // Keep checking until the backend has finished.
    receipt.whenData((r) {
      if (r.status == ReceiptStatus.processing) _poll();
    });

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 64,
        leading: const Padding(padding: EdgeInsets.only(left: 20), child: CircleBackButton()),
        title: const Text('Receipt'),
      ),
      body: receipt.when(
        // Keep showing the old data during a background refresh.
        skipLoadingOnRefresh: true,
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: error is Failure ? error.message : 'Could not load this receipt.',
          onRetry: () => ref.invalidate(receiptProvider(widget.id)),
        ),
        data: (r) => _Body(receipt: r),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.receipt});

  final Receipt receipt;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(receipt.title, style: AppTextStyles.heading),
        const SizedBox(height: 6),
        Row(
          children: [
            StatusChip(receipt.status),
            const SizedBox(width: 10),
            Text(formatDate(receipt.date), style: AppTextStyles.caption),
          ],
        ),
        const SizedBox(height: 20),
        if (receipt.status == ReceiptStatus.processing)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('Reading your receipt. This usually takes a few seconds.')),
          )
        else if (receipt.status == ReceiptStatus.failed)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('We could not read this receipt. Try scanning it again.')),
          )
        else ...[
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                for (final item in receipt.items)
                  ListTile(
                    title: Text(item.name),
                    subtitle: item.category == null ? null : Text(item.category!),
                    trailing: Text(formatMoney(item.price * item.quantity, receipt.currency)),
                    dense: true,
                  ),
                if (receipt.items.isEmpty)
                  const Padding(padding: EdgeInsets.all(16), child: Text('No line items found.')),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
                  trailing: Text(
                    formatMoney(receipt.total, receipt.currency),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          if (receipt.status == ReceiptStatus.needsReview)
            Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Some numbers did not add up, so please check them against the photo.',
                style: TextStyle(color: AppColors.amberInk),
              ),
            ),
          const SizedBox(height: 16),
          AppButton(
            label: receipt.status == ReceiptStatus.needsReview ? 'Review and confirm' : 'Edit',
            variant: receipt.status == ReceiptStatus.needsReview
                ? AppButtonVariant.filled
                : AppButtonVariant.outlined,
            onPressed: () => context.push(RoutePaths.receiptEditFor(receipt.id)),
          ),
        ],
        if (receipt.imageUrl != null) ...[
          const SizedBox(height: 20),
          Text('Original photo', style: AppTextStyles.subheading),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => context.push(RoutePaths.receiptPhotoFor(receipt.id)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 260,
                width: double.infinity,
                child: ReceiptImage(receipt: receipt),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text('Tap the photo to enlarge it', style: AppTextStyles.caption),
        ],
      ],
    );
  }
}
