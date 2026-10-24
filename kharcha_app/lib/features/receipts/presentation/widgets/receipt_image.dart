import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:kharcha_app/core/theme/app_colors.dart';
import 'package:kharcha_app/features/receipts/domain/entities/receipt.dart';
import 'package:kharcha_app/features/receipts/presentation/widgets/money.dart';

/// The URL scheme demo receipts use instead of a real photo link.
const String demoImageScheme = 'demo://';

/// The photo of a receipt, wherever the app shows one.
///
/// * a real receipt: the picture from the server, remembered on the phone so
///   it still shows with no internet once it has been seen;
/// * a demo receipt (imageUrl starts with demo://): a paper receipt drawn
///   from the receipt's own data, so the demo needs no image files;
/// * no picture yet: a grey placeholder.
class ReceiptImage extends StatelessWidget {
  const ReceiptImage({
    super.key,
    required this.receipt,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.topCenter,
  });

  final Receipt receipt;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final url = receipt.imageUrl;
    if (url == null || url.isEmpty) return const _Placeholder(icon: Icons.receipt_long_outlined);
    if (url.startsWith(demoImageScheme)) {
      return FittedBox(
        fit: fit,
        alignment: alignment,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(width: 300, child: GeneratedReceipt(receipt: receipt)),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      // Signed links expire and change; the receipt id does not, so the saved copy keeps being found.
      cacheKey: 'receipt-${receipt.id}',
      fit: fit,
      alignment: alignment,
      placeholder: (_, __) => const _Placeholder(),
      errorWidget: (_, __, ___) => const _Placeholder(icon: Icons.broken_image_outlined),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.icon});

  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.track,
      child: Center(
        child: icon == null
            ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
            : Icon(icon, color: AppColors.muted),
      ),
    );
  }
}

/// A till receipt drawn in Flutter from a [Receipt]'s data (demo mode only).
class GeneratedReceipt extends StatelessWidget {
  const GeneratedReceipt({super.key, required this.receipt});

  final Receipt receipt;

  @override
  Widget build(BuildContext context) {
    const mono = TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.35, color: Color(0xFF222222));
    const bold = TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.35, color: Color(0xFF222222), fontWeight: FontWeight.w700);

    Widget line(String left, String right, {TextStyle style = mono}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(left, style: style, maxLines: 2, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Text(right, style: style),
            ],
          ),
        );

    const rule = Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Text('- - - - - - - - - - - - - - - - - - -', style: mono, maxLines: 1, overflow: TextOverflow.clip),
    );

    final currency = receipt.currency;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
      decoration: const BoxDecoration(
        color: Color(0xFFFDFCF7),
        boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(receipt.title.toUpperCase(), textAlign: TextAlign.center, style: bold.copyWith(fontSize: 15)),
          const SizedBox(height: 2),
          Text('Kathmandu, Nepal', textAlign: TextAlign.center, style: mono),
          if (receipt.date != null) Text(formatDate(receipt.date), textAlign: TextAlign.center, style: mono),
          rule,
          if (receipt.items.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('. . .', textAlign: TextAlign.center, style: mono))
          else
            for (final i in receipt.items)
              line(
                i.quantity > 1 ? '${i.quantity} x ${i.name}' : i.name,
                (i.price * i.quantity).toStringAsFixed(2),
              ),
          rule,
          line('TOTAL', '$currency ${(receipt.total ?? receipt.itemsSum).toStringAsFixed(2)}', style: bold),
          const SizedBox(height: 8),
          Text('Thank you, visit again', textAlign: TextAlign.center, style: mono),
        ],
      ),
    );
  }
}
