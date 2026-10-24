import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kharcha_app/core/utils/date_utils.dart';
import 'package:kharcha_app/features/dashboard/di/dashboard_di.dart';
import 'package:kharcha_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:kharcha_app/features/dashboard/domain/entities/month_total.dart';

/// The month the Home tab is showing, as "YYYY-MM". Starts on the current
/// month; the month picker and the arrows change it. Never goes past this month.
class SelectedMonth extends Notifier<String> {
  @override
  String build() => monthKey(DateTime.now());

  void set(String month) {
    final current = monthKey(DateTime.now());
    state = month.compareTo(current) > 0 ? current : month;
  }

  void shift(int delta) => set(shiftMonth(state, delta));

  bool get isCurrent => state == monthKey(DateTime.now());
}

final selectedMonthProvider = NotifierProvider<SelectedMonth, String>(SelectedMonth.new);

/// The summary of the month shown on Home. Failures are thrown so the page can show them.
final dashboardSummaryProvider = FutureProvider.autoDispose<DashboardSummary>((ref) async {
  final month = ref.watch(selectedMonthProvider);
  final isCurrent = month == monthKey(DateTime.now());
  final result = await ref.watch(getDashboardSummaryUseCaseProvider)(isCurrent ? null : month);
  return result.fold((failure) => throw failure, (summary) => summary);
});

/// Always the current month, whatever Home is showing. Insights uses this, so
/// browsing old months never changes this month's alerts.
final currentSummaryProvider = FutureProvider.autoDispose<DashboardSummary>((ref) async {
  final result = await ref.watch(getDashboardSummaryUseCaseProvider)(null);
  return result.fold((failure) => throw failure, (summary) => summary);
});

/// Monthly totals for the trends chart (the last 6 months, ending with this one).
final spendingTrendProvider = FutureProvider.autoDispose<List<MonthTotal>>((ref) async {
  final result = await ref.watch(getSpendingTrendUseCaseProvider)(6);
  return result.fold((failure) => throw failure, (list) => list);
});
