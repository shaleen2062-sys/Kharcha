/// Categories offered when editing a line item.
const List<String> receiptCategories = [
  'Groceries',
  'Dining',
  'Transport',
  'Shopping',
  'Health',
  'Bills',
  'Entertainment',
  'Rent',
  'Education',
  'Travel',
  'Personal Care',
  'Other',
];

/// Where a receipt is in the pipeline.
enum ReceiptStatus {
  processing, // uploaded, backend is still reading it
  needsReview, // read, but something looks off: user should check
  confirmed, // looks right
  failed; // could not be read

  /// The word the backend uses for this status.
  String get wire => switch (this) {
        ReceiptStatus.processing => 'processing',
        ReceiptStatus.needsReview => 'needs_review',
        ReceiptStatus.confirmed => 'confirmed',
        ReceiptStatus.failed => 'failed',
      };

  static ReceiptStatus parse(String? raw) {
    switch (raw) {
      case 'processing':
        return ReceiptStatus.processing;
      case 'needs_review':
        return ReceiptStatus.needsReview;
      case 'confirmed':
        return ReceiptStatus.confirmed;
      case 'failed':
        return ReceiptStatus.failed;
      default:
        return ReceiptStatus.processing;
    }
  }
}

class ReceiptItem {
  const ReceiptItem({
    required this.name,
    required this.price,
    this.quantity = 1,
    this.category,
  });

  final String name;
  final double price;
  final int quantity;
  final String? category;
}

/// Pure Dart: no JSON or Dio here.
class Receipt {
  const Receipt({
    required this.id,
    required this.status,
    this.merchant,
    this.total,
    this.currency = 'NPR',
    this.date,
    this.imageUrl,
    this.items = const [],
  });

  final String id;
  final ReceiptStatus status;
  final String? merchant;
  final double? total;
  final String currency;
  final DateTime? date;
  final String? imageUrl;
  final List<ReceiptItem> items;

  Receipt copyWith({
    ReceiptStatus? status,
    String? merchant,
    double? total,
    String? currency,
    DateTime? date,
    List<ReceiptItem>? items,
  }) {
    return Receipt(
      id: id,
      status: status ?? this.status,
      merchant: merchant ?? this.merchant,
      total: total ?? this.total,
      currency: currency ?? this.currency,
      date: date ?? this.date,
      imageUrl: imageUrl,
      items: items ?? this.items,
    );
  }

  /// Sum of price x quantity over the line items.
  double get itemsSum => items.fold(0.0, (sum, i) => sum + i.price * i.quantity);

  /// True when the items do not add up to the total (more than 1 paisa off).
  bool get totalMismatch => total != null && items.isNotEmpty && (itemsSum - total!).abs() > 0.01;

  String get title => (merchant == null || merchant!.trim().isEmpty) ? 'Receipt' : merchant!;
}
