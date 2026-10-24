import 'package:kharcha_app/core/network/category_names.dart';
import 'package:kharcha_app/features/receipts/domain/entities/receipt.dart';

double? _toDouble(Object? v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

class ReceiptItemModel {
  static ReceiptItem fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      name: (json['name'] as String?) ?? 'Item',
      price: _toDouble(json['price']) ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      category: CategoryNames.fromApi(json['category'] as String?),
    );
  }
}

String _two(int n) => n.toString().padLeft(2, '0');

/// JSON <-> Receipt. Tolerant on purpose: a missing field never crashes the
/// list, it just shows less.
class ReceiptModel {
  /// Full receipt as JSON, used for the offline cache. `fromJson(toJson(r))` gives r back.
  static Map<String, dynamic> toJson(Receipt r) {
    final d = r.date;
    return {
      'id': r.id,
      'status': r.status.wire,
      'merchant': r.merchant,
      'total': r.total,
      'currency': r.currency,
      'date': d == null ? null : '${d.year}-${_two(d.month)}-${_two(d.day)}',
      'imageUrl': r.imageUrl,
      'confidence': r.confidence,
      'confidenceReason': r.confidenceReason,
      'reviewReasons': r.reviewReasons,
      'tax': r.tax,
      'discount': r.discount,
      'cashPaid': r.cashPaid,
      'change': r.change,
      'items': [
        for (final i in r.items)
          {
            'name': i.name,
            'price': i.price,
            'quantity': i.quantity,
            'category': i.category,
          },
      ],
    };
  }

  /// Body for PATCH /api/receipts/:id. Saving always confirms the receipt.
  static Map<String, dynamic> toUpdateJson(Receipt r) {
    final d = r.date;
    return {
      'merchant': r.merchant,
      'total': r.total,
      'currency': r.currency,
      // Date only (no time zone), so the day never shifts.
      'date': d == null ? null : '${d.year}-${_two(d.month)}-${_two(d.day)}',
      'status': 'confirmed',
      'items': [
        for (final i in r.items)
          {
            'name': i.name,
            'price': i.price,
            'quantity': i.quantity,
            'category': CategoryNames.toApi(i.category),
          },
      ],
    };
  }

  static Receipt fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return Receipt(
      id: (json['id'] ?? json['_id']).toString(),
      status: ReceiptStatus.parse(json['status'] as String?),
      merchant: json['merchant'] as String?,
      total: _toDouble(json['total']),
      currency: (json['currency'] as String?) ?? 'NPR',
      date: json['date'] is String
          ? DateTime.tryParse(json['date'] as String)
          : null,
      imageUrl: json['imageUrl'] as String?,
      confidence: _toDouble(json['confidence']),
      confidenceReason: json['confidenceReason'] as String?,
      reviewReasons:
          (json['reviewReasons'] as List?)?.whereType<String>().toList() ??
          const [],
      tax: _toDouble(json['tax']),
      discount: _toDouble(json['discount']),
      cashPaid: _toDouble(json['cashPaid']),
      change: _toDouble(json['change']),
      items: rawItems is List
          ? rawItems
                .whereType<Map<String, dynamic>>()
                .map(ReceiptItemModel.fromJson)
                .toList()
          : const [],
    );
  }
}
