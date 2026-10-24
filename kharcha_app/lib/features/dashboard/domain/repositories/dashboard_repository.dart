import 'package:fpdart/fpdart.dart';

import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:kharcha_app/features/dashboard/domain/entities/month_total.dart';

abstract interface class DashboardRepository {
  /// [month] is "YYYY-MM"; null means the current month.
  Future<Either<Failure, DashboardSummary>> summary({String? month});

  /// Totals of the last [months] months ending with the current one, oldest first.
  Future<Either<Failure, List<MonthTotal>>> trend({int months = 6});
}
