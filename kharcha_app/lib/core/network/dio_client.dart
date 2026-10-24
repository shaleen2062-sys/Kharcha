import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:kharcha_app/core/config/env.dart';
import 'package:kharcha_app/core/network/auth_interceptor.dart';

/// Builds the app-wide Dio client.
Dio buildDio({required TokenProvider getToken}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 60),
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(AuthInterceptor(getToken: getToken, dio: dio));

  if (kDebugMode) {
    // Headers are left out on purpose so ID tokens never reach the console.
    dio.interceptors.add(
      LogInterceptor(requestHeader: false, requestBody: false, responseBody: false),
    );
  }

  return dio;
}
