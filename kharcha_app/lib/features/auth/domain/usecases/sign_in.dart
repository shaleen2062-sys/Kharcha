import 'package:fpdart/fpdart.dart';

import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/core/usecase/usecase.dart';
import 'package:kharcha_app/features/auth/domain/entities/app_user.dart';
import 'package:kharcha_app/features/auth/domain/repositories/auth_repository.dart';

class SignInParams {
  const SignInParams({required this.email, required this.password});

  final String email;
  final String password;
}

class SignIn implements UseCase<AppUser, SignInParams> {
  const SignIn(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, AppUser>> call(SignInParams params) {
    return _repository.signIn(email: params.email.trim(), password: params.password);
  }
}
