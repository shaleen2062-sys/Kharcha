import 'package:fpdart/fpdart.dart';

import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/features/budgets/domain/entities/budget.dart';

abstract interface class BudgetRepository {
  /// Budgets in force in [month] ("YYYY-MM", null = the current month), with
  /// what was spent that month.
  Future<Either<Failure, List<Budget>>> list({String? month});

  /// Creates the budget for a category, or changes its limit. The change
  /// applies from [month] onwards (null = the current month); earlier months
  /// keep the limit they had.
  Future<Either<Failure, Budget>> setLimit({required String category, required double limit, String? month});

  /// Stops the budget from [month] onwards; earlier months keep it.
  Future<Either<Failure, Unit>> remove(String category, {String? month});
}
