import 'dart:async';

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/core/usecase/usecase.dart';
import 'package:kharcha_app/core/sync/sync_service.dart';
import 'package:kharcha_app/features/receipts/di/receipts_di.dart';
import 'package:kharcha_app/features/receipts/domain/entities/receipt.dart';
import 'package:kharcha_app/features/receipts/domain/usecases/upload_receipt.dart';

/// The user's receipts, newest first as the backend returns them.
/// Failures are thrown so the page can show them with AsyncValue.error.
final receiptsProvider = FutureProvider.autoDispose<List<Receipt>>((ref) async {
  final result = await ref.watch(getReceiptsUseCaseProvider)(const NoParams());
  return result.fold((failure) => throw failure, (list) => list);
});

final receiptProvider = FutureProvider.autoDispose.family<Receipt, String>((
  ref,
  id,
) async {
  final result = await ref.watch(getReceiptUseCaseProvider)(id);
  return result.fold((failure) => throw failure, (receipt) => receipt);
});

/// How an upload ended.
enum UploadOutcome {
  uploaded, // the server has it
  queued, // no internet: saved on the phone, will upload by itself
  failed, // refused; the error is in the controller state
}

/// Uploading one scanned receipt. If there is no internet the photo is saved
/// to the phone's queue instead of being lost.
class UploadController extends Notifier<AsyncValue<Receipt?>> {
  @override
  AsyncValue<Receipt?> build() => const AsyncData<Receipt?>(null);

  Future<UploadOutcome> upload(Uint8List jpeg) async {
    state = const AsyncLoading<Receipt?>();
    final queue = ref.read(pendingUploadsProvider);
    final key = queue.newId();
    final result = await ref.read(uploadReceiptUseCaseProvider)(
      UploadReceiptParams(jpeg: jpeg, idempotencyKey: key),
    );
    return result.fold<Future<UploadOutcome>>(
      (Failure failure) async {
        if (failure is NetworkFailure) {
          final saved = await queue.add(jpeg, id: key);
          if (saved != null) {
            state = const AsyncData<Receipt?>(null);
            await ref.read(pendingCountProvider.notifier).refresh();
            unawaited(_reconcileQueuedUpload());
            return UploadOutcome.queued;
          }
          state = AsyncError<Receipt?>(
            const NetworkFailure(
              'No internet, and the photo could not be saved for later.',
            ),
            StackTrace.current,
          );
          return UploadOutcome.failed;
        }
        state = AsyncError<Receipt?>(failure, StackTrace.current);
        return UploadOutcome.failed;
      },
      (receipt) async {
        state = AsyncData<Receipt?>(receipt);
        ref.invalidate(receiptsProvider);
        return UploadOutcome.uploaded;
      },
    );
  }

  Future<void> _reconcileQueuedUpload() async {
    // A request can time out locally while the server is still receiving it.
    // Retry the same idempotency key after it has had time to finish; the
    // server will return the existing receipt instead of creating a duplicate.
    await Future<void>.delayed(const Duration(seconds: 5));
    try {
      await ref.read(pendingCountProvider.notifier).sync();
    } catch (_) {
      // The queue remains visible for the banner's manual retry.
    }
  }
}

final uploadControllerProvider =
    NotifierProvider.autoDispose<UploadController, AsyncValue<Receipt?>>(
      UploadController.new,
    );

/// How many photos are waiting for the internet. Lives for the whole app.
class PendingCount extends Notifier<int> {
  @override
  int build() => 0;

  Future<void> refresh() async {
    state = (await ref.read(pendingUploadsProvider).ids()).length;
  }

  /// Tries to send everything waiting. Safe to call any time.
  Future<SyncReport> sync() async {
    final report = await ref.read(pendingUploadSyncProvider).run();
    state = report.remaining;
    if (report.uploaded > 0) ref.invalidate(receiptsProvider);
    return report;
  }
}

final pendingCountProvider = NotifierProvider<PendingCount, int>(
  PendingCount.new,
);

/// Saving corrections on the review screen. Returns true on success.
class UpdateController extends Notifier<AsyncValue<Receipt?>> {
  @override
  AsyncValue<Receipt?> build() => const AsyncData<Receipt?>(null);

  Future<bool> save(Receipt receipt) async {
    state = const AsyncLoading<Receipt?>();
    final result = await ref.read(updateReceiptUseCaseProvider)(receipt);
    return result.fold(
      (Failure failure) {
        state = AsyncError<Receipt?>(failure, StackTrace.current);
        return false;
      },
      (saved) {
        state = AsyncData<Receipt?>(saved);
        ref.invalidate(receiptProvider(saved.id));
        ref.invalidate(receiptsProvider);
        return true;
      },
    );
  }
}

final updateControllerProvider =
    NotifierProvider.autoDispose<UpdateController, AsyncValue<Receipt?>>(
      UpdateController.new,
    );

class DeleteController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<bool> delete(String id) async {
    state = const AsyncLoading<void>();
    final result = await ref.read(deleteReceiptUseCaseProvider)(id);
    return result.fold(
      (Failure failure) {
        state = AsyncError<void>(failure, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData<void>(null);
        unawaited(ref.refresh(receiptsProvider.future));
        ref.invalidate(receiptProvider(id));
        return true;
      },
    );
  }
}

final deleteControllerProvider =
    NotifierProvider.autoDispose<DeleteController, AsyncValue<void>>(
      DeleteController.new,
    );
