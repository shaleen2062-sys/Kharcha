import 'package:dio/dio.dart';

import 'package:kharcha_app/core/error/exceptions.dart';
import 'package:kharcha_app/core/network/api_endpoints.dart';
import 'package:kharcha_app/core/network/api_error.dart';
import 'package:kharcha_app/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:kharcha_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:kharcha_app/features/dashboard/domain/entities/month_total.dart';

abstract interface class DashboardRemoteDataSource {
  Future<DashboardSummary> summary({String? month});
  Future<List<MonthTotal>> trend({int months = 6});
}

class DioDashboardRemoteDataSource implements DashboardRemoteDataSource {
  DioDashboardRemoteDataSource(this._dio);
  final Dio _dio;

  @override
  Future<DashboardSummary> summary({String? month}) async {
    try {
      final response = await _dio.get<Object?>(
        ApiEndpoints.dashboardSummary,
        queryParameters: month == null ? null : {'month': month},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final inner = data['summary'];
        return DashboardSummaryModel.fromJson(inner is Map<String, dynamic> ? inner : data);
      }
      throw const ServerException(message: 'Unexpected response from the server.');
    } on DioException catch (e) {
      final body = e.response?.data;
      final message = apiErrorMessage(body);
      throw ServerException(statusCode: e.response?.statusCode, message: message);
    }
  }

  @override
  Future<List<MonthTotal>> trend({int months = 6}) async {
    try {
      final response = await _dio.get<Object?>(ApiEndpoints.dashboardTrend, queryParameters: {'months': months});
      final data = response.data;
      final trend = data is Map<String, dynamic> ? data['trend'] : null;
      final list = trend is Map<String, dynamic> ? trend['months'] : (data is Map<String, dynamic> ? data['months'] : null);
      if (list is List) {
        return [
          for (final m in list.whereType<Map<String, dynamic>>())
            MonthTotal(month: (m['month'] as String?) ?? '', total: (m['total'] as num?)?.toDouble() ?? 0),
        ];
      }
      throw const ServerException(message: 'Unexpected response from the server.');
    } on DioException catch (e) {
      final body = e.response?.data;
      final message = apiErrorMessage(body);
      throw ServerException(statusCode: e.response?.statusCode, message: message);
    }
  }
}
