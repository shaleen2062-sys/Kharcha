import 'package:fpdart/fpdart.dart';

import 'package:kharcha_app/core/error/exceptions.dart';
import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:kharcha_app/features/auth/domain/entities/app_user.dart';
import 'package:kharcha_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Stream<AppUser?> authStateChanges() {
    return _remote.authStateChanges().map((model) => model?.toEntity());
  }

  @override
  Future<Either<Failure, AppUser>> signIn({
    required String email,
    required String password,
  }) {
    return _guard(() async {
      final model = await _remote.signIn(email: email, password: password);
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, AppUser>> signUp({
    required String email,
    required String password,
    String? displayName,
  }) {
    return _guard(() async {
      final model = await _remote.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, Unit>> sendPasswordReset({required String email}) {
    return _guard(() async {
      await _remote.sendPasswordReset(email: email);
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> signOut() {
    return _guard(() async {
      await _remote.signOut();
      return unit;
    });
  }

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
    } on AuthException catch (e) {
      return Left(_failureFor(e));
    } catch (_) {
      return Left(const UnknownFailure());
    }
  }

  Failure _failureFor(AuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return const NetworkFailure();
      case 'invalid-email':
        return AuthFailure('That email address is not valid.', code: e.code);
      case 'user-disabled':
        return AuthFailure('This account has been disabled.', code: e.code);
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return AuthFailure('Incorrect email or password.', code: e.code);
      case 'email-already-in-use':
        return AuthFailure('An account with this email already exists.', code: e.code);
      case 'weak-password':
        return AuthFailure('Choose a stronger password (at least 6 characters).', code: e.code);
      case 'too-many-requests':
        return AuthFailure('Too many attempts. Wait a moment and try again.', code: e.code);
      case 'operation-not-allowed':
        return AuthFailure('Email sign-in is not enabled for this project.', code: e.code);
      default:
        return AuthFailure('Could not complete the request. Please try again.', code: e.code);
    }
  }
}
