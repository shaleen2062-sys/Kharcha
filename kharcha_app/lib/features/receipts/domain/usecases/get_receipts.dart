import 'package:fpdart/fpdart.dart';

import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/core/usecase/usecase.dart';
import 'package:kharcha_app/features/receipts/domain/entities/receipt.dart';
import 'package:kharcha_app/features/receipts/domain/repositories/receipts_repository.dart';

class GetReceipts implements UseCase<List<Receipt>, NoParams> {
  const GetReceipts(this._repository);
  final ReceiptRepository _repository;

  @override
  Future<Either<Failure, List<Receipt>>> call(NoParams params) => _repository.list();
}
