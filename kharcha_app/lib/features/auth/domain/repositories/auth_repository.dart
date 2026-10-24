import 'package:fpdart/fpdart.dart';

import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/features/auth/domain/entities/app_user.dart';

abstract interface class AuthRepository {
  /// Emits the current user, or null when signed out. Emits once on startup
  /// with the restored session.
  Stream<AppUser?> authStateChanges();

  Future<Either<Failure, AppUser>> signIn({
    required String email,
    required String password,
  });
  Future<Either<Failure, AppUser>> signInWithGoogle();

  Future<Either<Failure, AppUser>> signUp({
    required String email,
    required String password,
    String? displayName,
  });

  Future<Either<Failure, Unit>> sendPasswordReset({required String email});

  Future<Either<Failure, Unit>> signOut();
}
