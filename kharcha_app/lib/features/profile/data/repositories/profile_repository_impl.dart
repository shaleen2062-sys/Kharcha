import 'package:fpdart/fpdart.dart';

import 'package:kharcha_app/core/error/exceptions.dart';
import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/core/storage/json_cache.dart';
import 'package:kharcha_app/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:kharcha_app/features/profile/data/models/profile_model.dart';
import 'package:kharcha_app/features/profile/domain/entities/user_profile.dart';
import 'package:kharcha_app/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote, this._cache);
  final ProfileRemoteDataSource _remote;
  final JsonCache _cache;

  static const _key = 'profile';

  /// Online: fetch and remember. Offline: the last remembered profile, if any.
  @override
  Future<Either<Failure, UserProfile>> get() async {
    try {
      final profile = await _remote.get();
      await _cache.write(_key, ProfileModel.toJson(profile));
      return Right(profile);
    } on ServerException catch (e) {
      if (e.statusCode == null) {
        final raw = await _cache.read(_key);
        if (raw is Map<String, dynamic>) {
          return Right(ProfileModel.fromJson(raw));
        }
      }
      return Left(_failure(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, UserProfile>> save(UserProfile profile) async {
    try {
      final saved = await _remote.save(profile);
      await _cache.write(_key, ProfileModel.toJson(saved));
      return Right(saved);
    } on ServerException catch (e) {
      return Left(_failure(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  Failure _failure(ServerException e) {
    final code = e.statusCode;
    if (code == null) return const NetworkFailure();
    if (code == 401) {
      return const AuthFailure('Your session expired. Please sign in again.');
    }
    return e.message == null
        ? const ServerFailure.generic()
        : ServerFailure(e.message!);
  }
}
