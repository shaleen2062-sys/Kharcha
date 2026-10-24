import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kharcha_app/core/di/core_providers.dart';
import 'package:kharcha_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:kharcha_app/features/receipts/presentation/providers/receipts_providers.dart';

/// Wraps the whole app. Sends waiting receipts when the app opens signed in,
/// when someone signs in, and whenever the internet comes back.
class UploadSyncHost extends ConsumerStatefulWidget {
  const UploadSyncHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UploadSyncHost> createState() => _UploadSyncHostState();
}

class _UploadSyncHostState extends ConsumerState<UploadSyncHost> {
  Future<void> _sync() async {
    try {
      await ref.read(pendingCountProvider.notifier).refresh();
      if (ref.read(pendingCountProvider) > 0) {
        await ref.read(pendingCountProvider.notifier).sync();
      }
    } catch (_) {
      // Syncing is best effort; the banner's button lets the user retry.
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(isOnlineProvider, (previous, next) {
      final online = next.maybeWhen(data: (v) => v, orElse: () => false);
      if (online) _sync();
    });
    ref.listen(authStateProvider, (previous, next) {
      final signedIn = next.maybeWhen(data: (u) => u != null, orElse: () => false);
      if (signedIn) _sync();
    });
    return widget.child;
  }
}
