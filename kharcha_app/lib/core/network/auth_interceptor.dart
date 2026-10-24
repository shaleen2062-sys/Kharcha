import 'package:dio/dio.dart';

/// Gives the interceptor a Firebase ID token. [forceRefresh] asks Firebase for
/// a brand new token instead of the cached one.
typedef TokenProvider = Future<String?> Function({bool forceRefresh});

/// Adds `Authorization: Bearer <Firebase ID token>` to every request.
/// If the server answers 401, it refreshes the token and retries once.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.getToken, required this.dio});

  final TokenProvider getToken;
  final Dio dio;

  static const String _retriedKey = 'auth_retried';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final alreadyRetried = request.extra[_retriedKey] == true;

    if (err.response?.statusCode == 401 && !alreadyRetried) {
      final freshToken = await getToken(forceRefresh: true);
      if (freshToken != null) {
        request.extra[_retriedKey] = true;
        request.headers['Authorization'] = 'Bearer $freshToken';
        try {
          final response = await dio.fetch<dynamic>(request);
          return handler.resolve(response);
        } on DioException catch (retryError) {
          return handler.next(retryError);
        }
      }
    }
    handler.next(err);
  }
}
