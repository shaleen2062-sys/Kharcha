import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kharcha_app/core/di/core_providers.dart';
import 'package:kharcha_app/core/theme/app_colors.dart';

/// A small banner shown only while the device is offline.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key, this.message = 'You are offline. Some features need a connection.'});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider).maybeWhen(data: (value) => value, orElse: () => true);
    if (online) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.amberSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, size: 18, color: AppColors.amberInk),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: AppColors.amberInk, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
