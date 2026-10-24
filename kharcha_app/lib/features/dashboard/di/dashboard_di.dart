import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kharcha_app/core/config/env.dart';
import 'package:kharcha_app/core/demo/demo_repositories.dart';
import 'package:kharcha_app/core/di/core_providers.dart';
import 'package:kharcha_app/core/di/storage_providers.dart';
import 'package:kharcha_app/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:kharcha_app/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:kharcha_app/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:kharcha_app/features/dashboard/domain/usecases/get_dashboard_summary.dart';
import 'package:kharcha_app/features/dashboard/domain/usecases/get_spending_trend.dart';

final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDataSource>(
  (ref) => DioDashboardRemoteDataSource(ref.watch(dioProvider)),
);

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  if (Env.useDemoData) return DemoDashboardRepository(ref.watch(demoStoreProvider));
  return DashboardRepositoryImpl(ref.watch(dashboardRemoteDataSourceProvider), ref.watch(jsonCacheProvider));
});

final getDashboardSummaryUseCaseProvider = Provider<GetDashboardSummary>(
  (ref) => GetDashboardSummary(ref.watch(dashboardRepositoryProvider)),
);

final getSpendingTrendUseCaseProvider = Provider<GetSpendingTrend>(
  (ref) => GetSpendingTrend(ref.watch(dashboardRepositoryProvider)),
);
