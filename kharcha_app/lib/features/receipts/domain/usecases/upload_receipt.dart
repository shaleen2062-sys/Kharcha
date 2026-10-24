import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/core/usecase/usecase.dart';
import 'package:kharcha_app/features/receipts/domain/entities/receipt.dart';
import 'package:kharcha_app/features/receipts/domain/repositories/receipts_repository.dart';

class UploadReceiptParams {
  const UploadReceiptParams({required this.jpeg, this.idempotencyKey});

  final Uint8List jpeg;

  /// Same key on every retry of the same photo, so the backend can answer with
  /// the receipt it already made instead of creating a duplicate.
  final String? idempotencyKey;
}

class UploadReceipt implements UseCase<Receipt, UploadReceiptParams> {
  const UploadReceipt(this._repository);
  final ReceiptRepository _repository;

  @override
  Future<Either<Failure, Receipt>> call(UploadReceiptParams params) =>
      _repository.upload(params.jpeg, idempotencyKey: params.idempotencyKey);
}
