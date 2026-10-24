import 'package:flutter/material.dart';

import 'package:kharcha_app/core/theme/app_colors.dart';
import 'package:kharcha_app/features/dashboard/domain/entities/dashboard_summary.dart';

/// Tiny bar chart of spending per day, no chart package needed.
class DailyBars extends StatelessWidget {
  const DailyBars({super.key, required this.daily, this.height = 90});

  final List<DailySpend> daily;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (daily.isEmpty) return SizedBox(height: height);
    final peak = daily.map((d) => d.amount).fold<double>(0, (a, b) => b > a ? b : a);
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final d in daily)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Tooltip(
                  message: 'Day ${d.day}: ${d.amount.toStringAsFixed(0)}',
                  child: Container(
                    height: peak <= 0 ? 2 : (d.amount / peak * height).clamp(2.0, height),
                    decoration: BoxDecoration(
                      color: d.amount > 0 ? AppColors.primary : AppColors.track,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
