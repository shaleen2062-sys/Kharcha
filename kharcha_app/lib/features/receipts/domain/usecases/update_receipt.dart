import 'package:fpdart/fpdart.dart';

import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/core/usecase/usecase.dart';
import 'package:kharcha_app/features/receipts/domain/entities/receipt.dart';
import 'package:kharcha_app/features/receipts/domain/repositories/receipts_repository.dart';

class UpdateReceipt implements UseCase<Receipt, Receipt> {
  const UpdateReceipt(this._repository);
  final ReceiptRepository _repository;

  @override
  Future<Either<Failure, Receipt>> call(Receipt params) => _repository.update(params);
}
