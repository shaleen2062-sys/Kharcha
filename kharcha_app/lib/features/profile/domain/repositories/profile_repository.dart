import 'package:fpdart/fpdart.dart';

import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/features/profile/domain/entities/user_profile.dart';

abstract interface class ProfileRepository {
  /// The signed-in user's profile. A user who has never saved one gets a
  /// default profile with onboarded == false.
  Future<Either<Failure, UserProfile>> get();

  /// Saves the whole profile and returns what the server stored.
  Future<Either<Failure, UserProfile>> save(UserProfile profile);
}
