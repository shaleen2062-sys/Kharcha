import 'package:fpdart/fpdart.dart';

import 'package:kharcha_app/core/error/failures.dart';

/// One use case = one thing the app can do. Callable like a function:
///   final result = await signIn(SignInParams(...));
abstract interface class UseCase<T, P> {
  Future<Either<Failure, T>> call(P params);
}

/// For use cases that take no input.
class NoParams {
  const NoParams();
}
