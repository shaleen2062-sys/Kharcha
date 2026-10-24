import 'package:flutter/material.dart';

import 'package:kharcha_app/core/theme/app_colors.dart';
import 'package:kharcha_app/core/theme/category_style.dart';
import 'package:kharcha_app/features/receipts/domain/entities/receipt.dart';
import 'package:kharcha_app/features/receipts/presentation/widgets/money.dart';

/// One line of a receipt: name, quantity, category chip and the line cost.
class LineItemTile extends StatelessWidget {
  const LineItemTile(this.item, {this.currency = 'NPR', super.key});

  final ReceiptItem item;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(item.category);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(children: [
                  if (item.quantity > 1)
                    Text('${item.quantity} x ${formatMoney(item.price, currency)}   ', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: style.chipBg, borderRadius: BorderRadius.circular(12)),
                    child: Text(item.category ?? 'Uncategorized', style: TextStyle(color: style.chipFg, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ],
            ),
          ),
          Text(formatMoney(item.price * item.quantity, currency), style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
