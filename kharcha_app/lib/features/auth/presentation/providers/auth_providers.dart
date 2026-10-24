import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/core/usecase/usecase.dart';
import 'package:kharcha_app/features/auth/di/auth_di.dart';
import 'package:kharcha_app/features/auth/domain/entities/app_user.dart';
import 'package:kharcha_app/features/auth/domain/usecases/sign_in.dart';
import 'package:kharcha_app/features/auth/domain/usecases/sign_up.dart';

/// The signed-in user (null when signed out). The router listens to this.
final authStateProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(watchAuthStateUseCaseProvider)(),
);

/// Runs sign in, sign up, sign out and password reset.
/// The state is loading while a request runs, an error holding a [Failure] if it
/// fails, and data when it succeeds. Pages listen to it to show errors.
class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<bool> signIn(String email, String password) {
    return _run(
      () => ref.read(signInUseCaseProvider)(SignInParams(email: email, password: password)),
    );
  }

  Future<bool> signUp(String email, String password, {String? displayName}) {
    return _run(
      () => ref.read(signUpUseCaseProvider)(
        SignUpParams(email: email, password: password, displayName: displayName),
      ),
    );
  }

  Future<bool> sendPasswordReset(String email) {
    return _run(() => ref.read(sendPasswordResetUseCaseProvider)(email));
  }

  Future<bool> signOut() {
    return _run(() => ref.read(signOutUseCaseProvider)(const NoParams()));
  }

  /// Returns true on success. Navigation after sign in or out is handled by the
  /// router's auth guard, so pages do not navigate themselves.
  Future<bool> _run<T>(Future<Either<Failure, T>> Function() action) async {
    state = const AsyncLoading<void>();
    final result = await action();
    return result.fold(
      (failure) {
        state = AsyncError<void>(failure, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData<void>(null);
        return true;
      },
    );
  }
}

final authControllerProvider = NotifierProvider<AuthController, AsyncValue<void>>(
  AuthController.new,
);
