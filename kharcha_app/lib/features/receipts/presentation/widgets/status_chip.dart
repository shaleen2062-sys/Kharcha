import 'package:flutter/material.dart';

import 'package:kharcha_app/core/theme/app_colors.dart';
import 'package:kharcha_app/features/receipts/domain/entities/receipt.dart';

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final ReceiptStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      ReceiptStatus.processing => ('Reading...', AppColors.track, AppColors.muted),
      ReceiptStatus.needsReview => ('Needs review', AppColors.amberSoft, AppColors.amberInk),
      ReceiptStatus.confirmed => ('Confirmed', AppColors.primarySoft, AppColors.primarySoftInk),
      ReceiptStatus.failed => ('Could not read', AppColors.dangerSoft, AppColors.dangerInk),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
