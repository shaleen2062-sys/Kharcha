import 'package:fpdart/fpdart.dart';

import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/core/usecase/usecase.dart';
import 'package:kharcha_app/features/auth/domain/repositories/auth_repository.dart';

class SendPasswordReset implements UseCase<Unit, String> {
  const SendPasswordReset(this._repository);

  final AuthRepository _repository;

  /// [params] is the email address.
  @override
  Future<Either<Failure, Unit>> call(String params) {
    return _repository.sendPasswordReset(email: params.trim());
  }
}
