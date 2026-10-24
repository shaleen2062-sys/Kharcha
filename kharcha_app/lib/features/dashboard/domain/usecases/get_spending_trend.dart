import 'package:fpdart/fpdart.dart';

import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/core/usecase/usecase.dart';
import 'package:kharcha_app/features/dashboard/domain/entities/month_total.dart';
import 'package:kharcha_app/features/dashboard/domain/repositories/dashboard_repository.dart';

/// The monthly totals for the trends chart. The parameter is how many months (6 by default).
class GetSpendingTrend implements UseCase<List<MonthTotal>, int> {
  const GetSpendingTrend(this._repository);
  final DashboardRepository _repository;

  @override
  Future<Either<Failure, List<MonthTotal>>> call(int params) => _repository.trend(months: params);
}
