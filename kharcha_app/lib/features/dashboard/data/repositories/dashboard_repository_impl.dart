import 'package:fpdart/fpdart.dart';

import 'package:kharcha_app/core/error/exceptions.dart';
import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/core/storage/json_cache.dart';
import 'package:kharcha_app/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:kharcha_app/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:kharcha_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:kharcha_app/features/dashboard/domain/entities/month_total.dart';
import 'package:kharcha_app/features/dashboard/domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl(this._remote, this._cache);
  final DashboardRemoteDataSource _remote;
  final JsonCache _cache;

  /// Only the current month (month == null) is remembered for offline use.
  static const _key = 'dashboard_summary';

  @override
  Future<Either<Failure, DashboardSummary>> summary({String? month}) async {
    try {
      final summary = await _remote.summary(month: month);
      if (month == null)
        await _cache.write(_key, DashboardSummaryModel.toJson(summary));
      return Right(summary);
    } on ServerException catch (e) {
      final code = e.statusCode;
      if (code == null) {
        if (month == null) {
          final raw = await _cache.read(_key);
          if (raw is Map<String, dynamic>)
            return Right(DashboardSummaryModel.fromJson(raw));
        }
        return const Left(NetworkFailure());
      }
      if (code == 401)
        return const Left(
          AuthFailure('Your session expired. Please sign in again.'),
        );
      return Left(
        e.message == null
            ? const ServerFailure.generic()
            : ServerFailure(e.message!),
      );
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  static const _trendKey = 'dashboard_trend';

  @override
  Future<Either<Failure, List<MonthTotal>>> trend({int months = 6}) async {
    try {
      final list = await _remote.trend(months: months);
      await _cache.write(_trendKey, [
        for (final m in list) {'month': m.month, 'total': m.total},
      ]);
      return Right(list);
    } on ServerException catch (e) {
      final code = e.statusCode;
      if (code == null) {
        final raw = await _cache.read(_trendKey);
        if (raw is List) {
          return Right([
            for (final m in raw.whereType<Map<String, dynamic>>())
              MonthTotal(
                month: (m['month'] as String?) ?? '',
                total: (m['total'] as num?)?.toDouble() ?? 0,
              ),
          ]);
        }
        return const Left(NetworkFailure());
      }
      if (code == 401)
        return const Left(
          AuthFailure('Your session expired. Please sign in again.'),
        );
      return Left(
        e.message == null
            ? const ServerFailure.generic()
            : ServerFailure(e.message!),
      );
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
