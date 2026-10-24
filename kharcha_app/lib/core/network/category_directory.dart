import 'package:dio/dio.dart';

import 'package:kharcha_app/core/error/exceptions.dart';
import 'package:kharcha_app/core/network/api_endpoints.dart';
import 'package:kharcha_app/core/network/api_error.dart';
import 'package:kharcha_app/core/network/category_names.dart';

/// Budgets are stored per category id, but screens talk in category names.
/// This loads the user's categories once and answers "what is the id of Dining?".
class CategoryDirectory {
  CategoryDirectory(this._dio);
  final Dio _dio;

  Map<String, String>? _idByApiName; // backend name -> id

  Future<String> idFor(String appName) async {
    final map = _idByApiName ?? await _load();
    final apiName = CategoryNames.toApi(appName) ?? appName;
    final id = map[apiName];
    if (id == null) throw ServerException(message: 'Unknown category "$appName".');
    return id;
  }

  /// Call after signing out or when categories change.
  void reset() => _idByApiName = null;

  Future<Map<String, String>> _load() async {
    try {
      final response = await _dio.get<Object?>(ApiEndpoints.categories);
      final data = response.data;
      final list = data is Map<String, dynamic> ? data['categories'] : null;
      if (list is! List) throw const ServerException(message: 'Unexpected response from the server.');
      return _idByApiName = {
        for (final c in list.whereType<Map<String, dynamic>>()) (c['name'] as String): (c['id'] as String),
      };
    } on DioException catch (e) {
      throw ServerException(statusCode: e.response?.statusCode, message: apiErrorMessage(e.response?.data));
    }
  }
}
