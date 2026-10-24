import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kharcha_app/core/config/env.dart';
import 'package:kharcha_app/core/demo/demo_repositories.dart';
import 'package:kharcha_app/core/di/core_providers.dart';
import 'package:kharcha_app/core/di/storage_providers.dart';
import 'package:kharcha_app/features/receipts/data/datasources/receipts_remote_datasource.dart';
import 'package:kharcha_app/core/sync/sync_service.dart';
import 'package:kharcha_app/core/sync/pending_upload_queue.dart';
import 'package:kharcha_app/features/receipts/data/repositories/receipts_repository_impl.dart';
import 'package:kharcha_app/features/receipts/domain/repositories/receipts_repository.dart';
import 'package:kharcha_app/features/receipts/domain/usecases/get_receipt_detail.dart';
import 'package:kharcha_app/features/receipts/domain/usecases/get_receipts.dart';
import 'package:kharcha_app/features/receipts/domain/usecases/update_receipt.dart';
import 'package:kharcha_app/features/receipts/domain/usecases/delete_receipt.dart';
import 'package:kharcha_app/features/receipts/domain/usecases/upload_receipt.dart';

final receiptRemoteDataSourceProvider = Provider<ReceiptRemoteDataSource>(
  (ref) => DioReceiptRemoteDataSource(ref.watch(dioProvider)),
);

final receiptRepositoryProvider = Provider<ReceiptRepository>((ref) {
  if (Env.useDemoData)
    return DemoReceiptRepository(ref.watch(demoStoreProvider));
  return ReceiptRepositoryImpl(
    ref.watch(receiptRemoteDataSourceProvider),
    ref.watch(jsonCacheProvider),
  );
});

final pendingUploadsProvider = Provider<PendingUploads>(
  (ref) => PendingUploads(
    ref.watch(localStoreProvider),
    ref.watch(currentUidProvider),
  ),
);

final pendingUploadSyncProvider = Provider<PendingUploadSync>(
  (ref) => PendingUploadSync(
    ref.watch(pendingUploadsProvider),
    ref.watch(receiptRepositoryProvider),
  ),
);

final uploadReceiptUseCaseProvider = Provider<UploadReceipt>(
  (ref) => UploadReceipt(ref.watch(receiptRepositoryProvider)),
);
final getReceiptsUseCaseProvider = Provider<GetReceipts>(
  (ref) => GetReceipts(ref.watch(receiptRepositoryProvider)),
);
final updateReceiptUseCaseProvider = Provider<UpdateReceipt>(
  (ref) => UpdateReceipt(ref.watch(receiptRepositoryProvider)),
);
final getReceiptUseCaseProvider = Provider<GetReceipt>(
  (ref) => GetReceipt(ref.watch(receiptRepositoryProvider)),
);
final deleteReceiptUseCaseProvider = Provider<DeleteReceipt>(
  (ref) => DeleteReceipt(ref.watch(receiptRepositoryProvider)),
);
