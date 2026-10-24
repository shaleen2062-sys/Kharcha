import 'package:fpdart/fpdart.dart';

import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/core/usecase/usecase.dart';
import 'package:kharcha_app/features/receipts/domain/repositories/receipts_repository.dart';

class DeleteReceipt implements UseCase<Unit, String> {
  const DeleteReceipt(this._repository);
  final ReceiptRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String id) => _repository.delete(id);
}
