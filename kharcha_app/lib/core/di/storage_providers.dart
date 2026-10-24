import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kharcha_app/core/di/core_providers.dart';
import 'package:kharcha_app/core/storage/json_cache.dart';
import 'package:kharcha_app/core/storage/local_store.dart';
import 'package:kharcha_app/core/storage/local_store_factory.dart';

final localStoreProvider = Provider<LocalStore>((ref) => createLocalStore());

/// Reads the signed-in user's id at the moment it is called (not when the
/// provider is built), so cache and queue always follow the current user.
final currentUidProvider = Provider<String? Function()>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return () => auth.currentUser?.uid;
});

final jsonCacheProvider = Provider<JsonCache>(
  (ref) => JsonCache(ref.watch(localStoreProvider), ref.watch(currentUidProvider)),
);
