import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/core/router/route_names.dart';
import 'package:kharcha_app/core/theme/app_colors.dart';
import 'package:kharcha_app/core/theme/app_text_styles.dart';
import 'package:kharcha_app/core/widgets/error_view.dart';
import 'package:kharcha_app/core/widgets/loading_view.dart';
import 'package:kharcha_app/features/receipts/domain/entities/receipt.dart';
import 'package:kharcha_app/features/receipts/presentation/providers/receipts_providers.dart';
import 'package:kharcha_app/features/receipts/presentation/widgets/money.dart';
import 'package:kharcha_app/features/receipts/presentation/widgets/receipt_image.dart';
import 'package:kharcha_app/features/receipts/presentation/widgets/status_chip.dart';

/// The receipt photo full screen, pinch to zoom, with what was read from it.
/// On a wide screen (web, tablet) the details sit beside the photo; on a
/// phone they are a sheet you can pull up from the bottom.
class ReceiptPhotoPage extends ConsumerWidget {
  const ReceiptPhotoPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipt = ref.watch(receiptProvider(id));
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Receipt photo', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close),
          onPressed: () => context.canPop() ? context.pop() : context.go(RoutePaths.home),
        ),
      ),
      body: receipt.when(
        skipLoadingOnRefresh: true,
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: error is Failure ? error.message : 'Could not load this receipt.',
          onRetry: () => ref.invalidate(receiptProvider(id)),
        ),
        data: (r) => LayoutBuilder(
          builder: (context, box) {
            final photo = _Zoomable(receipt: r);
            if (box.maxWidth >= 760) {
              return Row(
                children: [
                  Expanded(child: photo),
                  SizedBox(
                    width: 360,
                    child: ColoredBox(color: AppColors.bg, child: _Details(receipt: r)),
                  ),
                ],
              );
            }
            return Stack(
              children: [
                Positioned.fill(child: photo),
                DraggableScrollableSheet(
                  initialChildSize: 0.16,
                  minChildSize: 0.1,
                  maxChildSize: 0.8,
                  builder: (context, controller) => Container(
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: _Details(receipt: r, controller: controller),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Zoomable extends StatelessWidget {
  const _Zoomable({required this.receipt});

  final Receipt receipt;

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 1,
      maxScale: 5,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ReceiptImage(receipt: receipt, fit: BoxFit.contain, alignment: Alignment.center),
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.receipt, this.controller});

  final Receipt receipt;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)),
          ),
        ),
        const SizedBox(height: 14),
        Text(receipt.title, style: AppTextStyles.heading),
        const SizedBox(height: 6),
        Row(
          children: [
            StatusChip(receipt.status),
            const SizedBox(width: 10),
            Text(formatDate(receipt.date), style: AppTextStyles.caption),
          ],
        ),
        const SizedBox(height: 14),
        if (receipt.items.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('No line items read yet.'))
        else
          for (final item in receipt.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.quantity > 1 ? '${item.quantity} x ${item.name}' : item.name),
                        if (item.category != null) Text(item.category!, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(formatMoney(item.price * item.quantity, receipt.currency)),
                ],
              ),
            ),
        const Divider(height: 24),
        Row(
          children: [
            const Expanded(child: Text('Total', style: TextStyle(fontWeight: FontWeight.w700))),
            Text(formatMoney(receipt.total, receipt.currency), style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        if (receipt.totalMismatch)
          Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text('The items do not add up to the total. Compare with the photo.',
                style: TextStyle(color: AppColors.amberInk)),
          ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => context.push(RoutePaths.receiptEditFor(receipt.id)),
          child: Text(receipt.status == ReceiptStatus.needsReview ? 'Review and confirm' : 'Edit'),
        ),
      ],
    );
  }
}
