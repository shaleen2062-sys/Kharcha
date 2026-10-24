import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/core/router/route_names.dart';
import 'package:kharcha_app/core/theme/app_colors.dart';
import 'package:kharcha_app/core/theme/app_text_styles.dart';
import 'package:kharcha_app/core/theme/category_style.dart';
import 'package:kharcha_app/core/widgets/app_button.dart';
import 'package:kharcha_app/core/widgets/app_snack_bar.dart';
import 'package:kharcha_app/core/widgets/empty_state.dart';
import 'package:kharcha_app/core/widgets/error_view.dart';
import 'package:kharcha_app/core/widgets/loading_view.dart';
import 'package:kharcha_app/features/budgets/presentation/providers/budgets_providers.dart';
import 'package:kharcha_app/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:kharcha_app/features/receipts/domain/entities/receipt.dart';
import 'package:kharcha_app/features/receipts/presentation/providers/receipts_providers.dart';
import 'package:kharcha_app/features/receipts/presentation/widgets/money.dart';

/// Review tab: receipts the reader was not sure about, one at a time.
/// Approve it as it is, or open the edit page to fix it first.
class ReviewPage extends ConsumerStatefulWidget {
  const ReviewPage({super.key});

  @override
  ConsumerState<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends ConsumerState<ReviewPage> {
  int _index = 0;
  final Set<String> _removedReceiptIds = <String>{};

  Future<void> _approve(Receipt receipt) async {
    final ok = await ref.read(updateControllerProvider.notifier).save(receipt);
    if (!mounted) return;
    if (ok) {
      // Confirmed receipts now count in the budgets and on Home.
      ref.invalidate(budgetsProvider);
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(currentSummaryProvider);
      ref.invalidate(spendingTrendProvider);
      ref.invalidate(budgetsForMonthProvider);
      AppSnackBar.success(context, 'Saved. It now counts in your budgets.');
    } else {
      AppSnackBar.error(
        context,
        ref.read(updateControllerProvider).error ?? 'Could not save.',
      );
    }
  }

  Future<void> _reject(Receipt receipt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject receipt?'),
        content: const Text(
          'This receipt and its photo will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: const Text('Reject and remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await ref
        .read(deleteControllerProvider.notifier)
        .delete(receipt.id);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _removedReceiptIds.add(receipt.id);
        _index = 0;
      });
      AppSnackBar.success(context, 'Receipt rejected and removed.');
    } else {
      AppSnackBar.error(
        context,
        ref.read(deleteControllerProvider).error ?? 'Could not remove receipt.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final receipts = ref.watch(receiptsProvider);
    final saving = ref.watch(updateControllerProvider).isLoading;

    return SafeArea(
      top: false,
      child: receipts.when(
        skipLoadingOnRefresh: true,
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: error is Failure
              ? error.message
              : 'Could not load your receipts.',
          onRetry: () => ref.invalidate(receiptsProvider),
        ),
        data: (all) {
          final queue = all
              .where(
                (r) =>
                    r.status == ReceiptStatus.needsReview &&
                    !_removedReceiptIds.contains(r.id),
              )
              .toList();
          if (queue.isEmpty) {
            return const EmptyState(
              icon: Icons.check_circle_outline,
              title: 'All caught up',
              message:
                  'Receipts that need a second look will show up here after you scan them.',
            );
          }
          final index = _index.clamp(0, queue.length - 1).toInt();
          final receipt = queue[index];

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Review receipt',
                      style: AppTextStyles.heading.copyWith(fontSize: 26),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.amberSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${index + 1} of ${queue.length}',
                      style: TextStyle(
                        color: AppColors.amberInk,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _Header(receipt: receipt),
              if (receipt.totalMismatch) ...[
                const SizedBox(height: 14),
                _MismatchNote(receipt: receipt),
              ],
              const SizedBox(height: 14),
              _Items(receipt: receipt),
              const SizedBox(height: 14),
              AppButton(
                label: 'Approve and save',
                isLoading: saving,
                onPressed: () => _approve(receipt),
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'Edit details',
                variant: AppButtonVariant.outlined,
                onPressed: saving
                    ? null
                    : () => context.push(RoutePaths.receiptEditFor(receipt.id)),
              ),
              const SizedBox(height: 8),
              AppButton(
                label: 'Reject and remove',
                variant: AppButtonVariant.outlined,
                isLoading: saving,
                onPressed: saving ? null : () => _reject(receipt),
              ),
              if (queue.length > 1)
                TextButton(
                  onPressed: saving
                      ? null
                      : () =>
                            setState(() => _index = (index + 1) % queue.length),
                  child: const Text('Skip for now'),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.receipt});
  final Receipt receipt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 84,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.track,
              borderRadius: BorderRadius.circular(10),
            ),
            child: receipt.imageUrl == null
                ? Text(
                    'Receipt photo',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      receipt.imageUrl!,
                      width: 64,
                      height: 84,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.receipt_long_outlined),
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receipt.title,
                  style: AppTextStyles.heading.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 4),
                Text(formatDate(receipt.date), style: AppTextStyles.caption),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    text: 'Total on receipt ',
                    style: AppTextStyles.caption,
                    children: [
                      TextSpan(
                        text: formatMoneyShort(receipt.total, receipt.currency),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                if (receipt.confidence != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'AI read confidence: ${(receipt.confidence!.clamp(0.0, 1.0) * 100).round()}%',
                    style: AppTextStyles.caption,
                  ),
                  if (receipt.confidenceReason != null &&
                      receipt.confidenceReason!.isNotEmpty)
                    Text(
                      receipt.confidenceReason!,
                      style: AppTextStyles.caption,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MismatchNote extends StatelessWidget {
  const _MismatchNote({required this.receipt});
  final Receipt receipt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.amberSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 26,
            color: AppColors.amberInk,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Items add up to ${formatMoneyShort(receipt.itemsSum, receipt.currency)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  receipt.reviewReasons.isEmpty
                      ? 'The receipt total reads ${formatMoneyShort(receipt.total, receipt.currency)}. Check the prices below against the photo.'
                      : 'The receipt total reads ${formatMoneyShort(receipt.total, receipt.currency)}. '
                            'Review reason: ${receipt.reviewReasons.join(', ')}.',
                  style: TextStyle(fontSize: 14, color: AppColors.amberInk),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Items extends StatelessWidget {
  const _Items({required this.receipt});
  final Receipt receipt;

  @override
  Widget build(BuildContext context) {
    if (receipt.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Text('No line items were found.'),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          for (var i = 0; i < receipt.items.length; i++)
            _ItemRow(
              item: receipt.items[i],
              currency: receipt.currency,
              last: i == receipt.items.length - 1,
            ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.currency,
    required this.last,
  });

  final ReceiptItem item;
  final String currency;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(item.category);
    final name = item.quantity > 1
        ? '${item.name} x${item.quantity}'
        : item.name;
    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: style.chipBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item.category ?? 'Other',
                    style: TextStyle(
                      color: style.chipFg,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            formatMoneyShort(item.price * item.quantity, currency),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
