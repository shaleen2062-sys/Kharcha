const List<String> _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// "September 2026"
String monthLabel(DateTime date) => '${_monthNames[date.month - 1]} ${date.year}';

/// Days left in the month after today (the last day gives 0).
int daysLeftInMonth(DateTime now) {
  final lastDay = DateTime(now.year, now.month + 1, 0).day;
  return lastDay - now.day;
}

String daysLeftText(DateTime now) {
  final left = daysLeftInMonth(now);
  if (left == 0) return 'last day of the month';
  return left == 1 ? '1 day to go' : '$left days to go';
}

// ---- Month keys ("YYYY-MM") --------------------------------------------------
// The dashboard, the calendar and the budgets all talk about months as these
// keys, the same format the backend uses in ?month=2026-10.

/// "2026-10"
String monthKey(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}';

/// First day of the month a key names. A key that is not "YYYY-MM" gives the
/// current month, so a bad value can never crash a screen.
DateTime monthStart(String key) {
  final parts = key.split('-');
  final y = parts.length == 2 ? int.tryParse(parts[0]) : null;
  final m = parts.length == 2 ? int.tryParse(parts[1]) : null;
  if (y == null || m == null || m < 1 || m > 12) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }
  return DateTime(y, m, 1);
}

/// The key [delta] months away: shiftMonth('2026-01', -1) is '2025-12'.
String shiftMonth(String key, int delta) {
  final start = monthStart(key);
  return monthKey(DateTime(start.year, start.month + delta, 1));
}

/// Number of days in the month a key names.
int daysInMonth(String key) {
  final start = monthStart(key);
  return DateTime(start.year, start.month + 1, 0).day;
}

/// "October 2026"
String monthLabelOfKey(String key) => monthLabel(monthStart(key));

/// "Oct"
String shortMonthName(int month) => _monthNames[month - 1].substring(0, 3);

/// How many empty cells a Sunday-first calendar grid needs before day 1.
int calendarLeadingBlanks(String key) => monthStart(key).weekday % 7;
