import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/core/theme/app_colors.dart';
import 'package:kharcha_app/core/theme/app_text_styles.dart';
import 'package:kharcha_app/core/utils/date_utils.dart';
import 'package:kharcha_app/core/widgets/empty_state.dart';
import 'package:kharcha_app/core/widgets/error_view.dart';
import 'package:kharcha_app/core/widgets/loading_view.dart';
import 'package:kharcha_app/core/widgets/screen_header.dart';
import 'package:kharcha_app/features/budgets/domain/entities/budget.dart';
import 'package:kharcha_app/features/budgets/presentation/providers/budgets_providers.dart';
import 'package:kharcha_app/features/budgets/presentation/widgets/budget_sheet.dart';
import 'package:kharcha_app/features/receipts/presentation/widgets/money.dart';

/// Budgets tab: one overall card, then a card per category. Tap a card to
/// change its limit; the plus button adds a category.
class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetsProvider);
    final used = budgets.maybeWhen(data: (l) => l.map((b) => b.category).toList(), orElse: () => <String>[]);
    final now = DateTime.now();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Budgets', style: AppTextStyles.heading.copyWith(fontSize: 26)),
                    Text(monthLabel(now), style: AppTextStyles.caption),
                  ],
                ),
              ),
              RoundIconButton(
                icon: Icons.add,
                label: 'Add budget',
                filled: true,
                onPressed: () => showBudgetSheet(context, usedCategories: used),
              ),
            ],
          ),
        ),
        Expanded(
          child: budgets.when(
            skipLoadingOnRefresh: true,
            loading: () => const LoadingView(),
            error: (error, _) => ErrorView(
              message: error is Failure ? error.message : 'Could not load your budgets.',
              onRetry: () => ref.invalidate(budgetsProvider),
            ),
            data: (list) {
              if (list.isEmpty) {
                return const EmptyState(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'No budgets yet',
                  message: 'Tap the plus to set a monthly limit. Kharcha warns you before you pass it.',
                );
              }
              return RefreshIndicator(
                onRefresh: () => ref.refresh(budgetsProvider.future),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    _OverallCard(budgets: list, now: now),
                    const SizedBox(height: 12),
                    for (final b in list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _BudgetCard(
                          budget: b,
                          onTap: () => showBudgetSheet(context, existing: b, usedCategories: used),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _OverallCard extends StatelessWidget {
  const _OverallCard({required this.budgets, required this.now});

  final List<Budget> budgets;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final currency = budgets.first.currency;
    final spent = budgets.fold<double>(0, (a, b) => a + b.spent);
    final limit = budgets.fold<double>(0, (a, b) => a + b.limit);
    final left = limit - spent;
    final days = daysLeftInMonth(now);
    final dayText = days == 0 ? 'the last day' : (days == 1 ? 'the next day' : 'the next $days days');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Expanded(child: Text('All categories', style: TextStyle(fontWeight: FontWeight.w600))),
              Text(
                '${formatMoneyShort(spent, currency)} of ${formatMoneyShort(limit, currency)}',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: limit <= 0 ? 0 : (spent / limit).clamp(0.0, 1.0).toDouble(),
              minHeight: 8,
              color: left < 0 ? AppColors.danger : AppColors.primary,
              backgroundColor: AppColors.track,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            left >= 0
                ? '${formatMoneyShort(left, currency)} left for $dayText'
                : '${formatMoneyShort(-left, currency)} over in total',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.budget, required this.onTap});

  final Budget budget;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg, bar) = switch (budget.level) {
      BudgetLevel.ok => ('On track', AppColors.primarySoft, AppColors.primarySoftInk, AppColors.primary),
      BudgetLevel.warning => ('Near limit', AppColors.amberSoft, AppColors.amberInk, AppColors.amber),
      BudgetLevel.over => ('Over budget', AppColors.dangerSoft, AppColors.dangerInk, AppColors.danger),
    };
    final remaining = budget.remaining;
    final detail = remaining >= 0
        ? '${formatMoneyShort(remaining, budget.currency)} left'
        : '${formatMoneyShort(-remaining, budget.currency)} over';

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(budget.category, style: const TextStyle(fontWeight: FontWeight.w600))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
                    child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: budget.ratio.clamp(0.0, 1.0).toDouble(),
                  minHeight: 6,
                  color: bar,
                  backgroundColor: AppColors.track,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${formatMoneyShort(budget.spent, budget.currency)} of ${formatMoneyShort(budget.limit, budget.currency)}',
                      style: AppTextStyles.caption,
                    ),
                  ),
                  Text(detail, style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
