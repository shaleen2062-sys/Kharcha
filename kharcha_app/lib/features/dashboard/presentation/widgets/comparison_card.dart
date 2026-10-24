import 'package:flutter/material.dart';

import 'package:kharcha_app/core/theme/app_colors.dart';
import 'package:kharcha_app/core/theme/app_text_styles.dart';
import 'package:kharcha_app/core/theme/category_style.dart';
import 'package:kharcha_app/core/utils/date_utils.dart';
import 'package:kharcha_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:kharcha_app/features/receipts/presentation/widgets/money.dart';

/// One row of the comparison: a category with this month's and last month's spend.
class CategoryChange {
  const CategoryChange({required this.category, required this.now, required this.before});

  final String category;
  final double now;
  final double before;

  double get delta => now - before;
}

/// Every category that has spend in either month, biggest change first.
List<CategoryChange> categoryChanges(DashboardSummary s) {
  final names = <String>{
    for (final c in s.byCategory) c.category,
    for (final c in s.previousByCategory) c.category,
  };
  double now(String name) {
    for (final c in s.byCategory) {
      if (c.category == name) return c.amount;
    }
    return 0;
  }

  final rows = [for (final n in names) CategoryChange(category: n, now: now(n), before: s.previousFor(n))]
    ..sort((a, b) => b.delta.abs().compareTo(a.delta.abs()));
  return rows;
}

/// This month against the month before: the two totals as bars, then what
/// changed in each category. Spending more is shown in amber, less in green.
class ComparisonCard extends StatelessWidget {
  const ComparisonCard({super.key, required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final lastKey = shiftMonth(s.month, -1);
    final thisName = shortMonthName(monthStart(s.month).month);
    final lastName = shortMonthName(monthStart(lastKey).month);
    final rows = categoryChanges(s).where((r) => r.delta.abs() >= 1).take(5).toList();
    final peak = s.total > s.previousTotal ? s.total : s.previousTotal;
    final change = s.changePercent;

    Widget bar(String label, double amount, Color color) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(width: 36, child: Text(label, style: AppTextStyles.caption)),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: peak <= 0 ? 0 : (amount / peak).clamp(0.0, 1.0).toDouble(),
                    minHeight: 10,
                    color: color,
                    backgroundColor: AppColors.track,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 84,
                child: Text(formatMoneyShort(amount, s.currency), textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );

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
            children: [
              Expanded(child: Text('$thisName vs $lastName', style: AppTextStyles.subheading)),
              if (change != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: change > 0 ? AppColors.amberSoft : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${change > 0 ? 'Up' : 'Down'} ${change.abs().round()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: change > 0 ? AppColors.amberInk : AppColors.primarySoftInk,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (s.previousTotal <= 0 && s.total <= 0)
            Text('No spending in either month yet.', style: TextStyle(color: AppColors.muted))
          else ...[
            bar(thisName, s.total, AppColors.primary),
            bar(lastName, s.previousTotal, AppColors.isDark ? const Color(0xFF5E7A6E) : const Color(0xFF9FB8AE)),
            if (s.previousTotal <= 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('Nothing to compare with: no spending recorded in $lastName.', style: AppTextStyles.caption),
              ),
          ],
          if (rows.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 20),
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(color: CategoryStyle.of(r.category).bar, shape: BoxShape.circle),
                    ),
                    Expanded(child: Text(r.category)),
                    Text(
                      '${r.delta > 0 ? '+' : '-'}${formatMoneyShort(r.delta.abs(), s.currency)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: r.delta > 0 ? AppColors.amberInk : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
