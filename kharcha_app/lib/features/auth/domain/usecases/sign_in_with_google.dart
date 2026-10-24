import 'package:fpdart/fpdart.dart';

import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/core/usecase/usecase.dart';
import 'package:kharcha_app/features/auth/domain/entities/app_user.dart';
import 'package:kharcha_app/features/auth/domain/repositories/auth_repository.dart';

class SignInWithGoogle implements UseCase<AppUser, NoParams> {
  const SignInWithGoogle(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, AppUser>> call(NoParams params) =>
      _repository.signInWithGoogle();
}
