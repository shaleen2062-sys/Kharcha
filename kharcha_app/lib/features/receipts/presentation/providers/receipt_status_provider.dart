import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kharcha_app/features/receipts/di/receipts_di.dart';
import 'package:kharcha_app/features/receipts/domain/entities/receipt.dart';
import 'package:kharcha_app/features/receipts/domain/usecases/watch_receipt_status.dart';

final watchReceiptStatusProvider =
    Provider<WatchReceiptStatus>((ref) => WatchReceiptStatus(ref.watch(receiptRepositoryProvider)));

/// Live status of one receipt while it is being read:  ref.watch(receiptStatusProvider(id)).
final receiptStatusProvider = StreamProvider.autoDispose.family<Receipt, String>(
  (ref, id) => ref.watch(watchReceiptStatusProvider)(id),
);
