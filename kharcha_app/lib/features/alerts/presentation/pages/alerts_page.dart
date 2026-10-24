import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/core/router/route_names.dart';
import 'package:kharcha_app/core/theme/app_colors.dart';
import 'package:kharcha_app/core/widgets/empty_state.dart';
import 'package:kharcha_app/core/widgets/error_view.dart';
import 'package:kharcha_app/core/widgets/loading_view.dart';
import 'package:kharcha_app/features/alerts/domain/entities/app_alert.dart';
import 'package:kharcha_app/features/alerts/presentation/providers/alerts_providers.dart';

class AlertsPage extends ConsumerWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          TextButton(
            onPressed: (alerts.value?.unreadCount ?? 0) == 0
                ? null
                : () async {
                    await ref.read(alertsRemoteProvider).markAllRead();
                    ref.invalidate(alertsProvider);
                  },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: alerts.when(
        skipLoadingOnRefresh: true,
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e is Failure ? e.message : 'Could not load your alerts.',
          onRetry: () => ref.invalidate(alertsProvider),
        ),
        data: (state) => state.alerts.isEmpty
            ? const EmptyState(
                icon: Icons.notifications_none_rounded,
                title: 'No alerts',
                message: 'You will be told here when a budget is close to its limit.',
              )
            : RefreshIndicator(
                onRefresh: () => ref.refresh(alertsProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.alerts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _AlertTile(state.alerts[i]),
                ),
              ),
      ),
    );
  }
}

class _AlertTile extends ConsumerWidget {
  const _AlertTile(this.alert);
  final AppAlert alert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (icon, color) = switch (alert.kind) {
      AlertKind.budgetExceeded => (Icons.error_outline_rounded, AppColors.dangerInk),
      AlertKind.budgetWarning => (Icons.warning_amber_rounded, AppColors.amberInk),
      AlertKind.possibleDuplicate => (Icons.copy_all_rounded, AppColors.amberInk),
      AlertKind.needsReview => (Icons.fact_check_outlined, AppColors.primarySoftInk),
      AlertKind.other => (Icons.notifications_none_rounded, AppColors.muted),
    };
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          if (!alert.read) {
            await ref.read(alertsRemoteProvider).markRead(alert.id);
            ref.invalidate(alertsProvider);
          }
          if (alert.receiptId != null && context.mounted) {
            context.push(RoutePaths.receiptDetailFor(alert.receiptId!));
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  alert.message,
                  style: TextStyle(color: AppColors.ink, fontWeight: alert.read ? FontWeight.w400 : FontWeight.w700),
                ),
              ),
              if (!alert.read)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
