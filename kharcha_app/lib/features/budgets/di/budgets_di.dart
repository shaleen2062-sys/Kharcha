import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kharcha_app/core/config/env.dart';
import 'package:kharcha_app/core/demo/demo_repositories.dart';
import 'package:kharcha_app/core/di/core_providers.dart';
import 'package:kharcha_app/core/di/storage_providers.dart';
import 'package:kharcha_app/features/budgets/data/datasources/budget_remote_datasource.dart';
import 'package:kharcha_app/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:kharcha_app/features/budgets/domain/repositories/budget_repository.dart';
import 'package:kharcha_app/features/budgets/domain/usecases/budget_usecases.dart';

final budgetRemoteDataSourceProvider = Provider<BudgetRemoteDataSource>(
  (ref) => DioBudgetRemoteDataSource(ref.watch(dioProvider), ref.watch(categoryDirectoryProvider)),
);

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  if (Env.useDemoData) return DemoBudgetRepository(ref.watch(demoStoreProvider));
  return BudgetRepositoryImpl(ref.watch(budgetRemoteDataSourceProvider), ref.watch(jsonCacheProvider));
});

final getBudgetsUseCaseProvider =
    Provider<GetBudgets>((ref) => GetBudgets(ref.watch(budgetRepositoryProvider)));
final setBudgetUseCaseProvider =
    Provider<SetBudget>((ref) => SetBudget(ref.watch(budgetRepositoryProvider)));
final removeBudgetUseCaseProvider =
    Provider<RemoveBudget>((ref) => RemoveBudget(ref.watch(budgetRepositoryProvider)));
