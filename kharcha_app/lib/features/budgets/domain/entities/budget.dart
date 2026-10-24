enum BudgetLevel { ok, warning, over }

/// A monthly limit for one category, with what has been spent so far.
/// Pure Dart: `spent` is worked out by the backend from confirmed receipts.
class Budget {
  const Budget({
    required this.category,
    required this.limit,
    this.spent = 0,
    this.currency = 'NPR',
  });

  final String category;
  final double limit;
  final double spent;
  final String currency;

  /// 0.0 to 1.0+ (can go past 1 when over budget).
  double get ratio => limit <= 0 ? 0 : spent / limit;
  double get remaining => limit - spent;

  /// Warning from 80% of the limit, over from 100%.
  BudgetLevel get level => levelAt(80);

  /// Like [level], but warning starts at [warnPercent] (the user's alert setting).
  BudgetLevel levelAt(int warnPercent) {
    if (limit <= 0) return BudgetLevel.ok;
    if (ratio >= 1) return BudgetLevel.over;
    if (ratio * 100 >= warnPercent) return BudgetLevel.warning;
    return BudgetLevel.ok;
  }

  Budget copyWith({double? limit}) =>
      Budget(category: category, limit: limit ?? this.limit, spent: spent, currency: currency);
}
