import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/core/sync/pending_upload_queue.dart';
import 'package:kharcha_app/features/receipts/domain/repositories/receipts_repository.dart';

class SyncReport {
  const SyncReport({this.uploaded = 0, this.dropped = 0, this.remaining = 0, this.stoppedBy});

  final int uploaded;

  /// Photos the server will never accept (not an image, too large...): removed.
  final int dropped;

  /// Still waiting.
  final int remaining;

  /// Why it stopped early (offline, signed out, server down), if it did.
  final Failure? stoppedBy;
}

/// Sends waiting photos oldest first. Stops at the first problem that a retry
/// could fix, so nothing is lost and the order is kept.
class PendingUploadSync {
  PendingUploadSync(this._queue, this._repository);

  final PendingUploads _queue;
  final ReceiptRepository _repository;
  bool _running = false;

  /// 4xx answers that mean "this photo will never work". 401, 408 and 429 are
  /// not in the list: those can succeed later.
  static bool isPermanent(Failure f) {
    if (f is! ServerFailure) return false;
    final code = f.statusCode;
    if (code == null || code < 400 || code >= 500) return false;
    return code != 401 && code != 408 && code != 429;
  }

  Future<SyncReport> run() async {
    if (_running) return SyncReport(remaining: (await _queue.ids()).length);
    _running = true;
    var uploaded = 0;
    var dropped = 0;
    Failure? stoppedBy;
    try {
      for (final id in await _queue.ids()) {
        final bytes = await _queue.read(id);
        if (bytes == null) {
          await _queue.remove(id);
          continue;
        }
        final result = await _repository.upload(bytes, idempotencyKey: id);
        final failure = result.fold<Failure?>((f) => f, (_) => null);
        if (failure == null) {
          await _queue.remove(id);
          uploaded++;
        } else if (isPermanent(failure)) {
          await _queue.remove(id);
          dropped++;
        } else {
          stoppedBy = failure;
          break;
        }
      }
    } finally {
      _running = false;
    }
    return SyncReport(
      uploaded: uploaded,
      dropped: dropped,
      remaining: (await _queue.ids()).length,
      stoppedBy: stoppedBy,
    );
  }
}
