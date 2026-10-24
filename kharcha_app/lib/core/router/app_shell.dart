import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kharcha_app/core/config/env.dart';
import 'package:kharcha_app/core/router/route_names.dart';
import 'package:kharcha_app/core/theme/app_colors.dart';
import 'package:kharcha_app/core/widgets/offline_banner.dart';
import 'package:kharcha_app/features/receipts/domain/entities/receipt.dart';
import 'package:kharcha_app/features/receipts/presentation/providers/receipts_providers.dart';
import 'package:kharcha_app/features/receipts/presentation/widgets/pending_uploads_banner.dart';

/// Frame around the four main tabs: banners on top, the bottom navigation
/// bar below. Home, Review, Budgets and Insights live inside it; the scanner
/// and receipt pages open full screen above it.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (Env.useDemoData) const _DemoStrip(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: OfflineBanner(),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: PendingUploadsBanner(),
            ),
            Expanded(child: shell),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        index: shell.currentIndex,
        onSelect: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        onScan: () => context.push(RoutePaths.scan),
      ),
    );
  }
}

class _DemoStrip extends StatelessWidget {
  const _DemoStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.amberSoft,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        'Demo data: nothing here is saved to a server',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.amberInk,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BottomNav extends ConsumerWidget {
  const _BottomNav({
    required this.index,
    required this.onSelect,
    required this.onScan,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waiting = ref
        .watch(receiptsProvider)
        .maybeWhen(
          data: (list) =>
              list.where((r) => r.status == ReceiptStatus.needsReview).length,
          orElse: () => 0,
        );

    Widget tab(int i, IconData icon, String label, {int badge = 0}) => Expanded(
      child: _NavItem(
        icon: icon,
        label: label,
        selected: index == i,
        badge: badge,
        onTap: () => onSelect(i),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: Row(
            children: [
              tab(0, Icons.home_outlined, 'Home'),
              tab(1, Icons.receipt_long_outlined, 'Review', badge: waiting),
              // No camera on web, so the centre button is left out there.
              if (!kIsWeb)
                Expanded(
                  child: Center(
                    child: Semantics(
                      button: true,
                      label: 'Scan receipt',
                      child: GestureDetector(
                        onTap: onScan,
                        child: Transform.translate(
                          offset: const Offset(0, -14),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x590B6B57),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.photo_camera_outlined,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              tab(2, Icons.account_balance_wallet_outlined, 'Budgets'),
              tab(3, Icons.bar_chart_rounded, 'Insights'),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.muted;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, size: 24, color: color),
              if (badge > 0)
                Positioned(
                  right: -10,
                  top: -6,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.amber,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$badge',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.amberInk,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
