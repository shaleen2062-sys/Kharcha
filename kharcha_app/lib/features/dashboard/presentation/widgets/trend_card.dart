import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/core/theme/app_colors.dart';
import 'package:kharcha_app/core/theme/app_text_styles.dart';
import 'package:kharcha_app/core/utils/date_utils.dart';
import 'package:kharcha_app/features/dashboard/domain/entities/month_total.dart';
import 'package:kharcha_app/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:kharcha_app/features/receipts/presentation/widgets/money.dart';

/// "Spending trend": one bar per month for the last 6 months. Tap a bar to see its amount.
class TrendCard extends ConsumerWidget {
  const TrendCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trend = ref.watch(spendingTrendProvider);
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
          Text('Spending trend', style: AppTextStyles.subheading),
          const SizedBox(height: 2),
          Text('Last 6 months', style: AppTextStyles.caption),
          const SizedBox(height: 14),
          trend.when(
            skipLoadingOnRefresh: true,
            loading: () => const SizedBox(height: 150, child: Center(child: CircularProgressIndicator())),
            error: (error, _) => SizedBox(
              height: 150,
              child: Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(spendingTrendProvider),
                  child: Text(error is Failure ? '${error.message} Tap to retry.' : 'Could not load. Tap to retry.'),
                ),
              ),
            ),
            data: (months) => TrendBars(months: months),
          ),
        ],
      ),
    );
  }
}

/// "Up 12% from the month before", or null when there is nothing to compare with.
String? trendChangeText(double? previous, double current) {
  if (previous == null || previous <= 0) return null;
  final pct = ((current - previous) / previous * 100).round();
  if (pct == 0) return 'Same as the month before';
  return '${pct > 0 ? 'Up' : 'Down'} ${pct.abs()}% from the month before';
}

/// The bars themselves. Public so it can be tried with fixed data in tests.
class TrendBars extends StatefulWidget {
  const TrendBars({super.key, required this.months, this.currency = 'NPR'});

  final List<MonthTotal> months;
  final String currency;

  @override
  State<TrendBars> createState() => _TrendBarsState();
}

class _TrendBarsState extends State<TrendBars> {
  int? _picked; // index of the tapped bar; null = the latest month

  @override
  Widget build(BuildContext context) {
    final months = widget.months;
    if (months.isEmpty || months.every((m) => m.total <= 0)) {
      return SizedBox(
        height: 120,
        child: Center(child: Text('No spending to compare yet.', style: TextStyle(color: AppColors.muted))),
      );
    }
    final peak = months.map((m) => m.total).reduce((a, b) => a > b ? a : b);
    final index = (_picked ?? months.length - 1).clamp(0, months.length - 1);
    final shown = months[index];
    final previous = index > 0 ? months[index - 1].total : null;

    final change = trendChangeText(previous, shown.total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${monthLabelOfKey(shown.month)}: ${formatMoneyShort(shown.total, widget.currency)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        if (change != null) Text(change, style: AppTextStyles.caption),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < months.length; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    label: '${monthLabelOfKey(months[i].month)}, ${formatMoneyShort(months[i].total, widget.currency)}',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _picked = i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: FractionallySizedBox(
                                heightFactor: peak <= 0 ? 0.02 : (months[i].total / peak).clamp(0.02, 1.0).toDouble(),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: i == index ? AppColors.primary : AppColors.primarySoft,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                  ),
                                  child: const SizedBox(width: double.infinity),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < months.length; i++)
              Expanded(
                child: Text(
                  shortMonthName(monthStart(months[i].month).month),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: i == index ? FontWeight.w700 : FontWeight.w400,
                    color: i == index ? AppColors.ink : AppColors.muted,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
