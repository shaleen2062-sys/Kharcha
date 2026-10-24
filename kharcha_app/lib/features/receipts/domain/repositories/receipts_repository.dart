import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/features/receipts/domain/entities/receipt.dart';

abstract interface class ReceiptRepository {
  /// Sends the flattened JPEG. [idempotencyKey] goes out as the Idempotency-Key header.
  /// The backend answers right away with a receipt
  /// in `processing` state; the reading happens in its job queue.
  Future<Either<Failure, Receipt>> upload(
    Uint8List jpeg, {
    String? idempotencyKey,
  });

  Future<Either<Failure, List<Receipt>>> list();

  Future<Either<Failure, Receipt>> get(String id);

  /// Saves the user's corrections and marks the receipt confirmed.
  Future<Either<Failure, Receipt>> update(Receipt receipt);

  Future<Either<Failure, Unit>> delete(String id);
}
