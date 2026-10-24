/// "Rs 1,250.00". The app only uses Nepalese rupees, so the [currency] argument is ignored (kept so existing calls still compile).
/// No intl dependency: groups thousands by hand.
String formatMoney(double? amount, [String currency = 'NPR']) {
  if (amount == null) return '-';
  final fixed = amount.toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return 'Rs $whole.${parts[1]}';
}

String formatDate(DateTime? date) {
  if (date == null) return '';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

/// "Rs 42,380": whole rupees, used on the home, budgets and insights screens. [currency] is ignored (rupees only).
String formatMoneyShort(double? amount, [String currency = 'NPR']) {
  if (amount == null) return '-';
  final whole = amount.round().abs().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  final sign = amount.round() < 0 ? '-' : '';
  return '${sign}Rs $whole';
}
