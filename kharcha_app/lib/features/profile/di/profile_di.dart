import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kharcha_app/core/config/env.dart';
import 'package:kharcha_app/core/demo/demo_repositories.dart';
import 'package:kharcha_app/core/di/core_providers.dart';
import 'package:kharcha_app/core/di/storage_providers.dart';
import 'package:kharcha_app/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:kharcha_app/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:kharcha_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:kharcha_app/features/profile/domain/usecases/profile_usecases.dart';

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>(
  (ref) => DioProfileRemoteDataSource(ref.watch(dioProvider)),
);

/// Demo data or the real API, chosen by Env.useDemoData (same switch as every feature).
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  if (Env.useDemoData) return DemoProfileRepository(ref.watch(demoStoreProvider));
  return ProfileRepositoryImpl(ref.watch(profileRemoteDataSourceProvider), ref.watch(jsonCacheProvider));
});

final getProfileUseCaseProvider =
    Provider<GetProfile>((ref) => GetProfile(ref.watch(profileRepositoryProvider)));
final saveProfileUseCaseProvider =
    Provider<SaveProfile>((ref) => SaveProfile(ref.watch(profileRepositoryProvider)));
