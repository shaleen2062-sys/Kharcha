import 'package:fpdart/fpdart.dart';

import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/core/usecase/usecase.dart';
import 'package:kharcha_app/features/budgets/domain/entities/budget.dart';
import 'package:kharcha_app/features/budgets/domain/repositories/budget_repository.dart';

/// Params: the month as "YYYY-MM", or null for the current month.
class GetBudgets implements UseCase<List<Budget>, String?> {
  const GetBudgets(this._repository);
  final BudgetRepository _repository;

  @override
  Future<Either<Failure, List<Budget>>> call(String? params) => _repository.list(month: params);
}

class SetBudgetParams {
  const SetBudgetParams({required this.category, required this.limit, this.month});
  final String category;
  final double limit;

  /// The change applies from this month ("YYYY-MM") on; null = the current month.
  final String? month;
}

class SetBudget implements UseCase<Budget, SetBudgetParams> {
  const SetBudget(this._repository);
  final BudgetRepository _repository;

  @override
  Future<Either<Failure, Budget>> call(SetBudgetParams params) {
    if (params.limit <= 0) {
      return Future.value(const Left(UnknownFailure('The limit must be more than zero.')));
    }
    return _repository.setLimit(category: params.category, limit: params.limit, month: params.month);
  }
}

class RemoveBudgetParams {
  const RemoveBudgetParams({required this.category, this.month});
  final String category;
  final String? month;
}

class RemoveBudget implements UseCase<Unit, RemoveBudgetParams> {
  const RemoveBudget(this._repository);
  final BudgetRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(RemoveBudgetParams params) =>
      _repository.remove(params.category, month: params.month);
}
