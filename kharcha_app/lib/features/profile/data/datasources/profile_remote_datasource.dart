import 'package:dio/dio.dart';

import 'package:kharcha_app/core/error/exceptions.dart';
import 'package:kharcha_app/core/network/api_endpoints.dart';
import 'package:kharcha_app/core/network/api_error.dart';
import 'package:kharcha_app/features/profile/data/models/profile_model.dart';
import 'package:kharcha_app/features/profile/domain/entities/user_profile.dart';

abstract interface class ProfileRemoteDataSource {
  Future<UserProfile> get();
  Future<UserProfile> save(UserProfile profile);
}

class DioProfileRemoteDataSource implements ProfileRemoteDataSource {
  DioProfileRemoteDataSource(this._dio);
  final Dio _dio;

  @override
  Future<UserProfile> get() async {
    try {
      final response = await _dio.get<Object?>(ApiEndpoints.profile);
      final data = response.data;
      if (data is Map<String, dynamic>) return ProfileModel.fromJson(data);
      throw const ServerException(message: 'Unexpected response from the server.');
    } on DioException catch (e) {
      // A 404 would mean "new user"; the backend actually creates the user on this first call.
      if (e.response?.statusCode == 404) return const UserProfile();
      throw _toException(e);
    }
  }

  @override
  Future<UserProfile> save(UserProfile profile) async {
    try {
      final response = await _dio.patch<Object?>(ApiEndpoints.profile, data: ProfileModel.toJson(profile));
      final data = response.data;
      if (data is Map<String, dynamic>) return ProfileModel.fromJson(data);
      return profile; // 204 or an empty body: the server stored what we sent
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  ServerException _toException(DioException e) {
    final body = e.response?.data;
    final message = apiErrorMessage(body);
    return ServerException(statusCode: e.response?.statusCode, message: message);
  }
}
