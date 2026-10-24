import 'package:kharcha_app/core/config/app_constants.dart';
import 'package:kharcha_app/features/receipts/domain/entities/receipt.dart';
import 'package:kharcha_app/features/receipts/domain/repositories/receipts_repository.dart';

/// Follows a freshly uploaded receipt: asks the server every few seconds and emits each answer,
/// stopping as soon as the receipt is no longer "processing" (confirmed, needs review or failed).
class WatchReceiptStatus {
  const WatchReceiptStatus(this._repository);
  final ReceiptRepository _repository;

  Stream<Receipt> call(
    String id, {
    Duration every = AppConstants.receiptPollEvery,
    int maxPolls = AppConstants.receiptPollMax,
  }) async* {
    for (var i = 0; i < maxPolls; i++) {
      final result = await _repository.get(id);
      final receipt = result.fold((_) => null, (r) => r);
      if (receipt != null) {
        yield receipt;
        if (receipt.status != ReceiptStatus.processing) return;
      }
      await Future<void>.delayed(every);
    }
  }
}
