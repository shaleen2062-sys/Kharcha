class CategorySpend {
  const CategorySpend({required this.category, required this.amount});
  final String category;
  final double amount;
}

class DailySpend {
  const DailySpend({required this.day, required this.amount});

  /// Day of the month, 1 to 31.
  final int day;
  final double amount;
}

/// One month of spending, worked out by the backend from confirmed receipts.
/// Pure Dart: no JSON here.
class DashboardSummary {
  const DashboardSummary({
    required this.month,
    required this.total,
    this.previousTotal = 0,
    this.currency = 'NPR',
    this.receiptCount = 0,
    this.byCategory = const [],
    this.daily = const [],
    this.previousByCategory = const [],
  });

  /// "YYYY-MM"
  final String month;
  final double total;
  final double previousTotal;
  final String currency;
  final int receiptCount;
  final List<CategorySpend> byCategory;
  final List<DailySpend> daily;

  /// What each category came to in the month before, for the month-vs-month card.
  final List<CategorySpend> previousByCategory;

  /// Change against last month in percent, or null when there is nothing to
  /// compare with (last month was zero).
  double? get changePercent => previousTotal <= 0 ? null : (total - previousTotal) / previousTotal * 100;

  bool get isEmpty => total <= 0 && receiptCount == 0;

  /// Categories largest first.
  List<CategorySpend> get topCategories =>
      [...byCategory]..sort((a, b) => b.amount.compareTo(a.amount));

  /// Spend in [category] last month (0 when there was none).
  double previousFor(String category) {
    for (final c in previousByCategory) {
      if (c.category == category) return c.amount;
    }
    return 0;
  }

  /// Amount spent on [day] (1 to 31), 0 when nothing was spent or the day is not listed.
  double spentOnDay(int day) {
    for (final d in daily) {
      if (d.day == day) return d.amount;
    }
    return 0;
  }
}
