import 'package:kharcha_app/features/auth/domain/entities/app_user.dart';
import 'package:kharcha_app/features/auth/domain/repositories/auth_repository.dart';

/// A stream, so it does not use the UseCase interface (that one returns a Future).
class WatchAuthState {
  const WatchAuthState(this._repository);

  final AuthRepository _repository;

  Stream<AppUser?> call() => _repository.authStateChanges();
}
