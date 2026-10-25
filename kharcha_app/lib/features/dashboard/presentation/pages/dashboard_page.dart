import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/core/router/route_names.dart';
import 'package:kharcha_app/core/theme/app_colors.dart';
import 'package:kharcha_app/core/theme/app_text_styles.dart';
import 'package:kharcha_app/core/theme/category_style.dart';
import 'package:kharcha_app/core/utils/date_utils.dart';
import 'package:kharcha_app/core/widgets/empty_state.dart';
import 'package:kharcha_app/core/widgets/error_view.dart';
import 'package:kharcha_app/core/widgets/loading_view.dart';
import 'package:kharcha_app/core/widgets/screen_header.dart';
import 'package:kharcha_app/features/budgets/domain/entities/budget.dart';
import 'package:kharcha_app/features/budgets/presentation/providers/budgets_providers.dart';
import 'package:kharcha_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:kharcha_app/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:kharcha_app/features/dashboard/presentation/widgets/calendar_card.dart';
import 'package:kharcha_app/features/dashboard/presentation/widgets/comparison_card.dart';
import 'package:kharcha_app/features/dashboard/presentation/widgets/month_switcher.dart';
import 'package:kharcha_app/features/receipts/presentation/providers/receipts_providers.dart';
import 'package:kharcha_app/features/receipts/presentation/widgets/money.dart';
import 'package:kharcha_app/features/receipts/presentation/widgets/status_chip.dart';

/// Home tab: this month's spending against the budgets,
/// where the money went and the latest receipts. Laid out like the design.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(budgetsProvider);
    ref.invalidate(budgetsForMonthProvider);
    ref.invalidate(receiptsProvider);
    ref.invalidate(currentSummaryProvider);
    ref.invalidate(dashboardSummaryProvider);
    await ref.read(dashboardSummaryProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final now = DateTime.now();
    final month = ref.watch(selectedMonthProvider);
    final isCurrent = month == monthKey(now);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              const MonthSwitcher(),
              const Spacer(),
              RoundIconButton(
                icon: Icons.person_outline,
                label: 'Settings',
                onPressed: () => context.push(RoutePaths.settings),
              ),
              const SizedBox(width: 8),
              RoundIconButton(
                icon: Icons.notifications_none_rounded,
                label: 'Alerts',
                onPressed: () => context.push(RoutePaths.alerts),
              ),
            ],
          ),
        ),
        Expanded(
          child: summary.when(
            skipLoadingOnRefresh: true,
            loading: () => const LoadingView(),
            error: (error, _) => ErrorView(
              message: error is Failure
                  ? error.message
                  : 'Could not load your summary.',
              onRetry: () => ref.invalidate(dashboardSummaryProvider),
            ),
            data: (s) => RefreshIndicator(
              onRefresh: () => _refresh(ref),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  _TotalCard(
                    summary: s,
                    now: now,
                    month: month,
                    isCurrent: isCurrent,
                  ),
                  const SizedBox(height: 14),
                  if (s.isEmpty)
                    SizedBox(
                      height: 280,
                      child: EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: isCurrent
                            ? 'Nothing spent yet this month'
                            : 'Nothing spent in ${monthLabelOfKey(month)}',
                        message: isCurrent
                            ? 'Scan a receipt and approve it to see your spending here.'
                            : 'No approved receipts were found for this month.',
                      ),
                    )
                  else
                    _CategoriesCard(summary: s, month: month),
                  const SizedBox(height: 14),
                  CalendarCard(summary: s),
                  const SizedBox(height: 14),
                  ComparisonCard(summary: s),
                  if (isCurrent) ...[
                    const SizedBox(height: 14),
                    const _RecentReceipts(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: child,
    );
  }
}

/// The green card: spent so far, and how much of the total budget that is.
class _TotalCard extends ConsumerWidget {
  const _TotalCard({
    required this.summary,
    required this.now,
    required this.month,
    required this.isCurrent,
  });

  final DashboardSummary summary;
  final DateTime now;
  final String month;
  final bool isCurrent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const soft = Color(0xFFCFE8E0);
    final budgets = ref
        .watch(budgetsForMonthProvider(month))
        .maybeWhen(data: (v) => v, orElse: () => <Budget>[]);
    final budgetTotal = budgets.fold<double>(0, (a, b) => a + b.limit);
    final spent = summary.total;
    final change = summary.changePercent;

    String left;
    if (budgetTotal <= 0) {
      left = change == null
          ? '${summary.receiptCount} receipts'
          : '${change > 0 ? 'Up' : 'Down'} ${change.abs().round()}% from last month';
    } else if (spent <= budgetTotal) {
      left =
          '${formatMoneyShort(budgetTotal - spent, summary.currency)} left${isCurrent ? ', ${daysLeftText(now)}' : ''}';
    } else {
      left =
          '${formatMoneyShort(spent - budgetTotal, summary.currency)} over${isCurrent ? ', ${daysLeftText(now)}' : ''}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCurrent
                ? 'Spent this month'
                : 'Spent in ${monthLabelOfKey(month)}',
            style: TextStyle(color: soft, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Text(
            formatMoneyShort(spent, summary.currency),
            style: AppTextStyles.display.copyWith(
              color: Colors.white,
              fontSize: 38,
            ),
          ),
          if (budgetTotal > 0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (spent / budgetTotal).clamp(0.0, 1.0).toDouble(),
                minHeight: 8,
                color: Colors.white,
                backgroundColor: const Color(0x40FFFFFF),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (budgetTotal > 0)
                Flexible(
                  child: Text(
                    'of ${formatMoneyShort(budgetTotal, summary.currency)} budget',
                    style: const TextStyle(color: soft, fontSize: 14),
                  ),
                ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  left,
                  textAlign: budgetTotal > 0 ? TextAlign.end : TextAlign.start,
                  style: const TextStyle(color: soft, fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Where it went": each bar fills to the category's budget when it has one,
/// otherwise to its share of the biggest category.
class _CategoriesCard extends ConsumerWidget {
  const _CategoriesCard({required this.summary, required this.month});

  final DashboardSummary summary;
  final String month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = summary.topCategories;
    if (cats.isEmpty) return const SizedBox.shrink();
    final budgets = ref
        .watch(budgetsForMonthProvider(month))
        .maybeWhen(data: (v) => v, orElse: () => <Budget>[]);
    final byName = {for (final b in budgets) b.category: b};
    final top = cats.first.amount;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Where it went', style: AppTextStyles.subheading),
          const SizedBox(height: 12),
          for (final c in cats)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CategoryRow(
                name: c.category,
                amount: formatMoneyShort(c.amount, summary.currency),
                fill: byName[c.category] != null
                    ? byName[c.category]!.ratio
                    : (top <= 0 ? 0 : c.amount / top),
                color: switch (byName[c.category]?.level) {
                  BudgetLevel.over => AppColors.danger,
                  BudgetLevel.warning => AppColors.amber,
                  _ => CategoryStyle.of(c.category).bar,
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.name,
    required this.amount,
    required this.fill,
    required this.color,
  });

  final String name;
  final String amount;
  final double fill;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Text(amount, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: fill.clamp(0.0, 1.0).toDouble(),
            minHeight: 6,
            color: color,
            backgroundColor: AppColors.track,
          ),
        ),
      ],
    );
  }
}

class _RecentReceipts extends ConsumerWidget {
  const _RecentReceipts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipts = ref.watch(receiptsProvider);
    return receipts.maybeWhen(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        final recent = list.take(3).toList();
        return _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Recent receipts',
                      style: AppTextStyles.subheading,
                    ),
                  ),
                  InkWell(
                    onTap: () => context.push(RoutePaths.receipts),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 4,
                      ),
                      child: Text(
                        'See all',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              for (final r in recent)
                InkWell(
                  onTap: () => context.push(RoutePaths.receiptDetailFor(r.id)),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 56),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                formatDate(r.date),
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatMoneyShort(r.total, r.currency),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            StatusChip(r.status),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
