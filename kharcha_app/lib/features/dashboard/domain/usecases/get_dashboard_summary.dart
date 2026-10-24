import 'package:fpdart/fpdart.dart';

import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/core/usecase/usecase.dart';
import 'package:kharcha_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:kharcha_app/features/dashboard/domain/repositories/dashboard_repository.dart';

class GetDashboardSummary implements UseCase<DashboardSummary, String?> {
  const GetDashboardSummary(this._repository);
  final DashboardRepository _repository;

  @override
  Future<Either<Failure, DashboardSummary>> call(String? params) => _repository.summary(month: params);
}
