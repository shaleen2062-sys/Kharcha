import 'package:fpdart/fpdart.dart';

import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/core/usecase/usecase.dart';
import 'package:kharcha_app/features/auth/domain/entities/app_user.dart';
import 'package:kharcha_app/features/auth/domain/repositories/auth_repository.dart';

class SignUpParams {
  const SignUpParams({
    required this.email,
    required this.password,
    this.displayName,
  });

  final String email;
  final String password;
  final String? displayName;
}

class SignUp implements UseCase<AppUser, SignUpParams> {
  const SignUp(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, AppUser>> call(SignUpParams params) {
    return _repository.signUp(
      email: params.email.trim(),
      password: params.password,
      displayName: params.displayName,
    );
  }
}
