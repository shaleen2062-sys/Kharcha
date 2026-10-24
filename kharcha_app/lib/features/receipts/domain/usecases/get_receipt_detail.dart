import 'package:fpdart/fpdart.dart';

import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/core/usecase/usecase.dart';
import 'package:kharcha_app/features/receipts/domain/entities/receipt.dart';
import 'package:kharcha_app/features/receipts/domain/repositories/receipts_repository.dart';

class GetReceipt implements UseCase<Receipt, String> {
  const GetReceipt(this._repository);
  final ReceiptRepository _repository;

  @override
  Future<Either<Failure, Receipt>> call(String params) => _repository.get(params);
}
