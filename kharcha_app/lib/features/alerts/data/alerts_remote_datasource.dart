import 'package:dio/dio.dart';

import 'package:kharcha_app/core/error/exceptions.dart';
import 'package:kharcha_app/core/network/api_endpoints.dart';
import 'package:kharcha_app/core/network/api_error.dart';
import 'package:kharcha_app/features/alerts/domain/entities/app_alert.dart';

class AlertsRemoteDataSource {
  AlertsRemoteDataSource(this._dio);
  final Dio _dio;

  Future<AlertsState> list() async {
    final data = await _send(() => _dio.get<Object?>(ApiEndpoints.alerts));
    if (data is! Map<String, dynamic>) return AlertsState.empty;
    final raw = data['alerts'];
    final alerts = raw is List ? raw.whereType<Map<String, dynamic>>().map(AppAlert.fromJson).toList() : <AppAlert>[];
    return AlertsState(alerts, (data['unreadCount'] as num?)?.toInt() ?? alerts.where((a) => !a.read).length);
  }

  Future<void> markRead(String id) async {
    await _send(() => _dio.post<Object?>(ApiEndpoints.alertRead(id)));
  }

  Future<void> markAllRead() async {
    await _send(() => _dio.post<Object?>(ApiEndpoints.alertsReadAll));
  }

  Future<Object?> _send(Future<Response<Object?>> Function() call) async {
    try {
      return (await call()).data;
    } on DioException catch (e) {
      throw ServerException(statusCode: e.response?.statusCode, message: apiErrorMessage(e.response?.data));
    }
  }
}
