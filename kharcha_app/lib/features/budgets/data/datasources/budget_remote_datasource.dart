import 'package:dio/dio.dart';

import 'package:kharcha_app/core/error/exceptions.dart';
import 'package:kharcha_app/core/network/api_endpoints.dart';
import 'package:kharcha_app/core/network/api_error.dart';
import 'package:kharcha_app/core/network/category_directory.dart';
import 'package:kharcha_app/features/budgets/data/models/budget_model.dart';
import 'package:kharcha_app/features/budgets/domain/entities/budget.dart';

abstract interface class BudgetRemoteDataSource {
  Future<List<Budget>> list({String? month});
  Future<Budget> setLimit(String category, double limit, {String? month});
  Future<void> remove(String category, {String? month});
}

class DioBudgetRemoteDataSource implements BudgetRemoteDataSource {
  DioBudgetRemoteDataSource(this._dio, this._categories);
  final Dio _dio;
  final CategoryDirectory _categories;

  @override
  Future<List<Budget>> list({String? month}) async {
    final data = await _send(
      () => _dio.get<Object?>(
        ApiEndpoints.budgets,
        queryParameters: month == null ? null : {'month': month},
      ),
    );
    final raw = data is Map<String, dynamic> ? data['budgets'] : data;
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(BudgetModel.fromJson)
        .toList();
  }

  @override
  Future<Budget> setLimit(
    String category,
    double limit, {
    String? month,
  }) async {
    final data = await _send(
      () async => _dio.put<Object?>(
        ApiEndpoints.budget(await _categories.idFor(category)),
        // effectiveFrom: the limit applies from this month on; earlier months keep theirs.
        data: {'limit': limit, 'effectiveFrom': ?month},
      ),
    );
    if (data is Map<String, dynamic>) {
      final inner = data['budget'];
      return BudgetModel.fromJson(inner is Map<String, dynamic> ? inner : data);
    }
    throw const ServerException(
      message: 'Unexpected response from the server.',
    );
  }

  @override
  Future<void> remove(String category, {String? month}) async {
    final id = await _categories.idFor(category);
    await _send(
      () => _dio.delete<Object?>(
        ApiEndpoints.budget(id),
        queryParameters: month == null ? null : {'effectiveFrom': month},
      ),
    );
  }

  Future<Object?> _send(Future<Response<Object?>> Function() call) async {
    try {
      return (await call()).data;
    } on DioException catch (e) {
      final body = e.response?.data;
      final message = apiErrorMessage(body);
      throw ServerException(
        statusCode: e.response?.statusCode,
        message: message,
      );
    }
  }
}
