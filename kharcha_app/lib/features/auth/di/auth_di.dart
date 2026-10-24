import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kharcha_app/core/di/core_providers.dart';
import 'package:kharcha_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:kharcha_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:kharcha_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:kharcha_app/features/auth/domain/usecases/send_password_reset.dart';
import 'package:kharcha_app/features/auth/domain/usecases/sign_in.dart';
import 'package:kharcha_app/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:kharcha_app/features/auth/domain/usecases/sign_out.dart';
import 'package:kharcha_app/features/auth/domain/usecases/sign_up.dart';
import 'package:kharcha_app/features/auth/domain/usecases/watch_auth_state.dart';

/// Wiring for the auth feature. This is the one file that sees both the data
/// and domain layers; presentation only imports it to get the use cases.

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => FirebaseAuthRemoteDataSource(ref.watch(firebaseAuthProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider)),
);

final signInUseCaseProvider = Provider<SignIn>(
  (ref) => SignIn(ref.watch(authRepositoryProvider)),
);

final signInWithGoogleUseCaseProvider = Provider<SignInWithGoogle>(
  (ref) => SignInWithGoogle(ref.watch(authRepositoryProvider)),
);

final signUpUseCaseProvider = Provider<SignUp>(
  (ref) => SignUp(ref.watch(authRepositoryProvider)),
);

final signOutUseCaseProvider = Provider<SignOut>(
  (ref) => SignOut(ref.watch(authRepositoryProvider)),
);

final sendPasswordResetUseCaseProvider = Provider<SendPasswordReset>(
  (ref) => SendPasswordReset(ref.watch(authRepositoryProvider)),
);

final watchAuthStateUseCaseProvider = Provider<WatchAuthState>(
  (ref) => WatchAuthState(ref.watch(authRepositoryProvider)),
);
