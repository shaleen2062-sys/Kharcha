import 'package:fpdart/fpdart.dart';

import 'package:kharcha_app/core/error/exceptions.dart';
import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/core/storage/json_cache.dart';
import 'package:kharcha_app/features/budgets/data/datasources/budget_remote_datasource.dart';
import 'package:kharcha_app/features/budgets/data/models/budget_model.dart';
import 'package:kharcha_app/features/budgets/domain/entities/budget.dart';
import 'package:kharcha_app/features/budgets/domain/repositories/budget_repository.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  BudgetRepositoryImpl(this._remote, this._cache);
  final BudgetRemoteDataSource _remote;
  final JsonCache _cache;

  /// One remembered list per month, so a past month still opens offline once seen.
  static String _key(String? month) =>
      month == null ? 'budgets' : 'budgets_$month';

  /// Online: fetch and remember. Offline: the last remembered list, if any.
  @override
  Future<Either<Failure, List<Budget>>> list({String? month}) async {
    final result = await _guard(() => _remote.list(month: month));
    return result.fold<Future<Either<Failure, List<Budget>>>>(
      (failure) async {
        if (failure is NetworkFailure) {
          final raw = await _cache.read(_key(month));
          if (raw is List) {
            return Right(
              raw
                  .whereType<Map<String, dynamic>>()
                  .map(BudgetModel.fromJson)
                  .toList(),
            );
          }
        }
        return Left(failure);
      },
      (list) async {
        await _cache.write(_key(month), [
          for (final b in list) BudgetModel.toJson(b),
        ]);
        return Right(list);
      },
    );
  }

  @override
  Future<Either<Failure, Budget>> setLimit({
    required String category,
    required double limit,
    String? month,
  }) => _guard(() => _remote.setLimit(category, limit, month: month));

  @override
  Future<Either<Failure, Unit>> remove(String category, {String? month}) =>
      _guard(() async {
        await _remote.remove(category, month: month);
        return unit;
      });

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
    } on ServerException catch (e) {
      final code = e.statusCode;
      if (code == null) return const Left(NetworkFailure());
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
