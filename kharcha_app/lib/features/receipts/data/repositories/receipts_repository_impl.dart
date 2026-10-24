import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import 'package:kharcha_app/core/error/exceptions.dart';
import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/core/storage/json_cache.dart';
import 'package:kharcha_app/features/receipts/data/datasources/receipts_remote_datasource.dart';
import 'package:kharcha_app/features/receipts/data/models/receipt_model.dart';
import 'package:kharcha_app/features/receipts/domain/entities/receipt.dart';
import 'package:kharcha_app/features/receipts/domain/repositories/receipts_repository.dart';

class ReceiptRepositoryImpl implements ReceiptRepository {
  ReceiptRepositoryImpl(this._remote, this._cache);

  final ReceiptRemoteDataSource _remote;
  final JsonCache _cache;

  static const _listKey = 'receipts';

  @override
  Future<Either<Failure, Receipt>> upload(
    Uint8List jpeg, {
    String? idempotencyKey,
  }) => _guard(() => _remote.upload(jpeg, idempotencyKey: idempotencyKey));

  /// Online: fetch and remember. Offline: the last remembered list, if any.
  @override
  Future<Either<Failure, List<Receipt>>> list() async {
    final result = await _guard(_remote.list);
    return result.fold<Future<Either<Failure, List<Receipt>>>>(
      (failure) async {
        if (failure is NetworkFailure) {
          final cached = await _cachedList();
          if (cached != null) return Right(cached);
        }
        return Left(failure);
      },
      (list) async {
        await _cache.write(_listKey, [
          for (final r in list) ReceiptModel.toJson(r),
        ]);
        return Right(list);
      },
    );
  }

  /// Offline: looks for the receipt in the remembered list.
  @override
  Future<Either<Failure, Receipt>> get(String id) async {
    final result = await _guard(() => _remote.get(id));
    return result.fold<Future<Either<Failure, Receipt>>>((failure) async {
      if (failure is NetworkFailure) {
        final cached = await _cachedList();
        final hit = cached?.where((r) => r.id == id);
        if (hit != null && hit.isNotEmpty) return Right(hit.first);
      }
      return Left(failure);
    }, (receipt) async => Right(receipt));
  }

  /// Needs the internet: edits are not queued.
  @override
  Future<Either<Failure, Receipt>> update(Receipt receipt) =>
      _guard(() => _remote.update(receipt));

  Future<List<Receipt>?> _cachedList() async {
    final raw = await _cache.read(_listKey);
    if (raw is! List) return null;
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ReceiptModel.fromJson)
        .toList();
  }

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
    } on ServerException catch (e) {
      final code = e.statusCode;
      if (code == null) return const Left(NetworkFailure());
      if (code == 401)
        return const Left(
          AuthFailure('Your session expired. Please sign in again.'),
        );
      if (code == 404)
        return Left(
          ServerFailure('That receipt was not found.', statusCode: code),
        );
      if (code == 413)
        return Left(
          ServerFailure('The photo is too large to upload.', statusCode: code),
        );
      return Left(
        e.message == null
            ? ServerFailure.generic(statusCode: code)
            : ServerFailure(e.message!, statusCode: code),
      );
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
