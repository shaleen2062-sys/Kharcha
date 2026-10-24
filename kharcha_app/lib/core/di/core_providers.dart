import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kharcha_app/core/config/env.dart';
import 'package:kharcha_app/core/network/category_directory.dart';

import 'package:kharcha_app/core/network/dio_client.dart';
import 'package:kharcha_app/core/network/network_info.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final categoryDirectoryProvider = Provider<CategoryDirectory>((ref) => CategoryDirectory(ref.watch(dioProvider)));

final dioProvider = Provider<Dio>((ref) {
  final auth = ref.watch(firebaseAuthProvider);

  Future<String?> getToken({bool forceRefresh = false}) async {
    if (Env.devAuthToken.isNotEmpty) return Env.devAuthToken;
    return await auth.currentUser?.getIdToken(forceRefresh);
  }

  return buildDio(getToken: getToken);
});

final networkInfoProvider = Provider<NetworkInfo>((ref) => NetworkInfo(Connectivity()));

/// true while the device has a network connection.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final info = ref.watch(networkInfoProvider);
  yield await info.isOnline;
  yield* info.onStatusChange;
});
