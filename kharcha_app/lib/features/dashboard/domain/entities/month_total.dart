/// The spending of one month, a bar in the trends chart. Pure Dart: no JSON here.
class MonthTotal {
  const MonthTotal({required this.month, required this.total});

  /// "YYYY-MM".
  final String month;
  final double total;
}
