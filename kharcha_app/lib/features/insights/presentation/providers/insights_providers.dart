import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kharcha_app/features/budgets/domain/entities/budget.dart';
import 'package:kharcha_app/features/budgets/presentation/providers/budgets_providers.dart';
import 'package:kharcha_app/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:kharcha_app/features/insights/domain/insights_builder.dart';
import 'package:kharcha_app/features/receipts/domain/entities/receipt.dart';
import 'package:kharcha_app/features/receipts/presentation/providers/receipts_providers.dart';

/// Alerts and summary sentences. Built from the three providers the other
/// screens already use, so there is no extra request.
final insightsProvider = Provider.autoDispose<AsyncValue<InsightsReport>>((ref) {
  final summary = ref.watch(currentSummaryProvider);
  final budgets = ref.watch(budgetsProvider);
  final receipts = ref.watch(receiptsProvider);

  // Show an error as soon as one source failed; show loading until all three are in.
  for (final source in <AsyncValue<Object?>>[summary, budgets, receipts]) {
    if (source.hasError && !source.hasValue) {
      return AsyncError<InsightsReport>(source.error!, source.stackTrace ?? StackTrace.current);
    }
  }
  if (!summary.hasValue || !budgets.hasValue || !receipts.hasValue) {
    return const AsyncLoading<InsightsReport>();
  }

  return AsyncData<InsightsReport>(buildInsights(
    budgets: budgets.value ?? const <Budget>[],
    receipts: receipts.value ?? const <Receipt>[],
    summary: summary.value,
    now: DateTime.now(),
  ));
});
