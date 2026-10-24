import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kharcha_app/core/config/env.dart';
import 'package:kharcha_app/core/di/core_providers.dart';
import 'package:kharcha_app/features/alerts/data/alerts_remote_datasource.dart';
import 'package:kharcha_app/features/alerts/domain/entities/app_alert.dart';

final alertsRemoteProvider = Provider<AlertsRemoteDataSource>((ref) => AlertsRemoteDataSource(ref.watch(dioProvider)));

/// The signed-in user's alerts. Demo mode has none (the Insights tab shows sample warnings instead).
final alertsProvider = FutureProvider.autoDispose<AlertsState>((ref) async {
  if (Env.useDemoData) return AlertsState.empty;
  return ref.watch(alertsRemoteProvider).list();
});

/// Number on the bell. Never throws: a failed request just hides the badge.
final unreadAlertsProvider = Provider.autoDispose<int>((ref) => ref.watch(alertsProvider).value?.unreadCount ?? 0);
