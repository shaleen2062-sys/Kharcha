import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/core/router/route_names.dart';
import 'package:kharcha_app/core/theme/app_colors.dart';
import 'package:kharcha_app/core/theme/app_text_styles.dart';
import 'package:kharcha_app/core/utils/date_utils.dart';
import 'package:kharcha_app/core/widgets/error_view.dart';
import 'package:kharcha_app/core/widgets/loading_view.dart';
import 'package:kharcha_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:kharcha_app/features/budgets/presentation/providers/budgets_providers.dart';
import 'package:kharcha_app/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:kharcha_app/features/dashboard/presentation/widgets/trend_card.dart';
import 'package:kharcha_app/features/insights/domain/insights_builder.dart';
import 'package:kharcha_app/features/insights/presentation/providers/insights_providers.dart';
import 'package:kharcha_app/features/receipts/presentation/providers/receipts_providers.dart';

/// Insights tab: every alert, a few plain sentences about the month, and the
/// account links (My receipts, Profile and settings) that have no tab of their own.
class InsightsPage extends ConsumerWidget {
  const InsightsPage({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(budgetsProvider);
    ref.invalidate(receiptsProvider);
    ref.invalidate(currentSummaryProvider);
    ref.invalidate(spendingTrendProvider);
  }

  void _open(BuildContext context, InsightTarget target) {
    switch (target) {
      case InsightTarget.budgets:
        context.go(RoutePaths.budgets);
      case InsightTarget.review:
        context.go(RoutePaths.review);
      case InsightTarget.receipts:
        context.push(RoutePaths.receipts);
      case InsightTarget.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(insightsProvider);
    final email = ref
        .watch(authStateProvider)
        .maybeWhen(data: (u) => u?.email, orElse: () => null);
    final now = DateTime.now();
    final left = daysLeftInMonth(now);
    final leftText = left == 0
        ? 'last day'
        : (left == 1 ? '1 day left' : '$left days left');

    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(
            'Alerts and insights',
            style: AppTextStyles.heading.copyWith(fontSize: 26),
          ),
          Text('${monthLabel(now)}, $leftText', style: AppTextStyles.caption),
          const SizedBox(height: 14),
          report.when(
            skipLoadingOnRefresh: true,
            loading: () => const SizedBox(height: 260, child: LoadingView()),
            error: (error, _) => SizedBox(
              height: 260,
              child: ErrorView(
                message: error is Failure
                    ? error.message
                    : 'Could not load your insights.',
                onRetry: () => _refresh(ref),
              ),
            ),
            data: (r) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (r.alerts.isEmpty)
                  const _NoAlerts()
                else
                  for (final a in r.alerts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AlertTile(
                        alert: a,
                        onTap: () => _open(context, a.target),
                      ),
                    ),
                const SizedBox(height: 4),
                _SummaryCard(points: r.points),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const TrendCard(),
          const SizedBox(height: 14),
          _AccountCard(
            email: email,
            onReceipts: () => context.push(RoutePaths.receipts),
            onSettings: () => context.push(RoutePaths.settings),
          ),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert, required this.onTap});

  final InsightAlert alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final danger = alert.level == InsightLevel.danger;
    final bg = danger ? AppColors.dangerSoft : AppColors.amberSoft;
    final ink = danger ? AppColors.dangerInk : AppColors.amberInk;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: alert.target == InsightTarget.none ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, size: 26, color: ink),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      alert.body,
                      style: TextStyle(fontSize: 14, color: AppColors.body),
                    ),
                  ],
                ),
              ),
              if (alert.target != InsightTarget.none)
                Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoAlerts extends StatelessWidget {
  const _NoAlerts();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 26,
            color: AppColors.primarySoftInk,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No alerts',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Every budget is on track and no receipt is waiting.',
                  style: TextStyle(fontSize: 14, color: AppColors.body),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.points});

  final List<String> points;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'This month so far',
                  style: AppTextStyles.subheading,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.blueSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Summary',
                  style: TextStyle(
                    color: AppColors.blueInk,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (points.isEmpty)
            const Text(
              'Approve a few receipts and a summary of your month will appear here.',
            )
          else
            for (final p in points)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 8, right: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(p, style: const TextStyle(height: 1.4)),
                    ),
                  ],
                ),
              ),
          Text(
            'Worked out from your approved receipts.',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.email,
    required this.onReceipts,
    required this.onSettings,
  });

  final String? email;
  final VoidCallback onReceipts;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    Widget row(
      IconData icon,
      String label,
      VoidCallback onTap, {
      Color? color,
    }) {
      final rowColor = color ?? AppColors.ink;
      return InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Row(
            children: [
              Icon(icon, size: 22, color: rowColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: rowColor,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (email != null)
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Text('Signed in as $email', style: AppTextStyles.caption),
            ),
          row(Icons.receipt_long_outlined, 'My receipts', onReceipts),
          Divider(height: 1, color: AppColors.divider),
          row(Icons.tune_rounded, 'Profile and settings', onSettings),
        ],
      ),
    );
  }
}
