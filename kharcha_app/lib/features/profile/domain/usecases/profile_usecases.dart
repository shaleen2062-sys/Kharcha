import 'package:fpdart/fpdart.dart';

import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/core/usecase/usecase.dart';
import 'package:kharcha_app/features/profile/domain/entities/user_profile.dart';
import 'package:kharcha_app/features/profile/domain/repositories/profile_repository.dart';

class GetProfile implements UseCase<UserProfile, NoParams> {
  const GetProfile(this._repository);
  final ProfileRepository _repository;

  @override
  Future<Either<Failure, UserProfile>> call(NoParams params) => _repository.get();
}

class SaveProfile implements UseCase<UserProfile, UserProfile> {
  const SaveProfile(this._repository);
  final ProfileRepository _repository;

  @override
  Future<Either<Failure, UserProfile>> call(UserProfile params) {
    if (params.displayName.trim().isEmpty) {
      return Future.value(const Left(UnknownFailure('Please enter your name.')));
    }
    if ((params.monthlyIncome ?? 0) < 0 || (params.totalBudget ?? 0) < 0) {
      return Future.value(const Left(UnknownFailure('Amounts cannot be negative.')));
    }
    if (params.alertPercent < 50 || params.alertPercent > 100) {
      return Future.value(const Left(UnknownFailure('The alert level must be between 50% and 100%.')));
    }
    return _repository.save(params);
  }
}
