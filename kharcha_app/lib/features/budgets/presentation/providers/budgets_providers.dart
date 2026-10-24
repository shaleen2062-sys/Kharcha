import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/core/utils/date_utils.dart';
import 'package:kharcha_app/features/budgets/di/budgets_di.dart';
import 'package:kharcha_app/features/budgets/domain/entities/budget.dart';
import 'package:kharcha_app/features/budgets/domain/usecases/budget_usecases.dart';
import 'package:kharcha_app/features/profile/presentation/providers/profile_providers.dart';

/// This month's budgets. Failures are thrown so pages can show them.
final budgetsProvider = FutureProvider.autoDispose<List<Budget>>((ref) async {
  final result = await ref.watch(getBudgetsUseCaseProvider)(null);
  return result.fold((failure) => throw failure, (list) => list);
});

/// The budgets of any month ("YYYY-MM"), as they were set then, with that
/// month's spending. The dashboard uses this for the month you are viewing.
final budgetsForMonthProvider = FutureProvider.autoDispose.family<List<Budget>, String>((ref, month) async {
  final current = monthKey(DateTime.now());
  final result = await ref.watch(getBudgetsUseCaseProvider)(month == current ? null : month);
  return result.fold((failure) => throw failure, (list) => list);
});

/// Budgets at the user's alert level (80% unless they changed it) or more,
/// worst first. These are the alerts.
final budgetAlertsProvider = Provider.autoDispose<List<Budget>>((ref) {
  final budgets = ref.watch(budgetsProvider).maybeWhen(data: (v) => v, orElse: () => <Budget>[]);
  final warnAt = ref.watch(profileProvider).value?.alertPercent ?? 80;
  final flagged = budgets.where((b) => b.levelAt(warnAt) != BudgetLevel.ok).toList()
    ..sort((a, b) => b.ratio.compareTo(a.ratio));
  return flagged;
});

/// Saves or deletes a budget. Each method returns the Failure on error, or
/// null on success, so the sheet or page can show it.
class BudgetActions extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  /// [month] ("YYYY-MM"): the change applies from that month on. Null = this month.
  Future<Failure?> save(String category, double limit, {String? month}) async {
    state = const AsyncLoading<void>();
    final result = await ref
        .read(setBudgetUseCaseProvider)(SetBudgetParams(category: category, limit: limit, month: month));
    return result.fold(
      (failure) {
        state = AsyncError<void>(failure, StackTrace.current);
        return failure;
      },
      (_) {
        state = const AsyncData<void>(null);
        ref.invalidate(budgetsProvider);
        ref.invalidate(budgetsForMonthProvider);
        return null;
      },
    );
  }

  Future<Failure?> remove(String category, {String? month}) async {
    state = const AsyncLoading<void>();
    final result =
        await ref.read(removeBudgetUseCaseProvider)(RemoveBudgetParams(category: category, month: month));
    return result.fold(
      (failure) {
        state = AsyncError<void>(failure, StackTrace.current);
        return failure;
      },
      (_) {
        state = const AsyncData<void>(null);
        ref.invalidate(budgetsProvider);
        ref.invalidate(budgetsForMonthProvider);
        return null;
      },
    );
  }
}

final budgetActionsProvider =
    NotifierProvider.autoDispose<BudgetActions, AsyncValue<void>>(BudgetActions.new);
