import 'package:flutter/material.dart';

import 'package:kharcha_app/core/theme/app_colors.dart';
import 'package:kharcha_app/features/receipts/domain/entities/receipt.dart';
import 'package:kharcha_app/features/receipts/presentation/widgets/money.dart';
import 'package:kharcha_app/features/receipts/presentation/widgets/status_chip.dart';

/// A receipt as a card in a list: store, date, total and where it is in the pipeline.
class ReceiptCard extends StatelessWidget {
  const ReceiptCard(this.receipt, {this.onTap, super.key});

  final Receipt receipt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(receipt.title, style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(formatDate(receipt.date), style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatMoney(receipt.total, receipt.currency), style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  StatusChip(receipt.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
