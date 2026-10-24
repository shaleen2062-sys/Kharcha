import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kharcha_app/core/router/route_names.dart';
import 'package:kharcha_app/core/theme/app_colors.dart';
import 'package:kharcha_app/features/budgets/domain/entities/budget.dart';
import 'package:kharcha_app/features/budgets/presentation/providers/budgets_providers.dart';
import 'package:kharcha_app/features/receipts/presentation/widgets/money.dart';

/// The worst budget problem as a tinted card on Home. Shows nothing when every
/// budget is fine. Tapping it opens the Insights tab, where all alerts are.
class BudgetAlertsBanner extends ConsumerWidget {
  const BudgetAlertsBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(budgetAlertsProvider);
    if (alerts.isEmpty) return const SizedBox.shrink();

    final worst = alerts.first;
    final isOver = worst.level == BudgetLevel.over;
    final ink = isOver ? AppColors.dangerInk : AppColors.amberInk;

    final title = isOver ? '${worst.category} is over budget' : '${worst.category} is near its limit';
    final body = isOver
        ? '${formatMoneyShort(-worst.remaining, worst.currency)} above the ${formatMoneyShort(worst.limit, worst.currency)} limit'
        : 'At ${(worst.ratio * 100).round()}% of its ${formatMoneyShort(worst.limit, worst.currency)} budget';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: isOver ? AppColors.dangerSoft : AppColors.amberSoft,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.go(RoutePaths.insights),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 26, color: ink),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
                        Text(body, style: TextStyle(fontSize: 14, color: AppColors.muted)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.muted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
