import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:kharcha_app/core/error/exceptions.dart';
import 'package:kharcha_app/core/network/api_endpoints.dart';
import 'package:kharcha_app/features/receipts/data/models/receipt_model.dart';
import 'package:kharcha_app/features/receipts/domain/entities/receipt.dart';

abstract interface class ReceiptRemoteDataSource {
  Future<Receipt> upload(Uint8List jpeg, {String? idempotencyKey});
  Future<List<Receipt>> list();
  Future<Receipt> get(String id);
  Future<Receipt> update(Receipt receipt);
}

class DioReceiptRemoteDataSource implements ReceiptRemoteDataSource {
  DioReceiptRemoteDataSource(this._dio);
  final Dio _dio;

  @override
  Future<Receipt> upload(Uint8List jpeg, {String? idempotencyKey}) async {
    final form = FormData.fromMap({
      'image': MultipartFile.fromBytes(jpeg, filename: 'receipt.jpg'),
    });
    final data = await _send(
      () => _dio.post<Object?>(
        ApiEndpoints.receipts,
        data: form,
        options: idempotencyKey == null ? null : Options(headers: {'Idempotency-Key': idempotencyKey}),
      ),
    );
    return ReceiptModel.fromJson(_receiptOf(data));
  }

  @override
  Future<List<Receipt>> list() async {
    final data = await _send(() => _dio.get<Object?>(ApiEndpoints.receipts));
    final raw = data is Map<String, dynamic> ? data['receipts'] : data;
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().map(ReceiptModel.fromJson).toList();
  }

  @override
  Future<Receipt> get(String id) async {
    final data = await _send(() => _dio.get<Object?>(ApiEndpoints.receipt(id)));
    return ReceiptModel.fromJson(_receiptOf(data));
  }

  @override
  Future<Receipt> update(Receipt receipt) async {
    final data = await _send(
      () => _dio.patch<Object?>(ApiEndpoints.receipt(receipt.id), data: ReceiptModel.toUpdateJson(receipt)),
    );
    return ReceiptModel.fromJson(_receiptOf(data));
  }

  /// The backend wraps a receipt as { "receipt": {...} }.
  Map<String, dynamic> _receiptOf(Object? data) {
    final map = _asMap(data);
    final inner = map['receipt'];
    return inner is Map<String, dynamic> ? inner : map;
  }

  Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    throw const ServerException(message: 'Unexpected response from the server.');
  }

  /// Turns Dio errors into ServerException. Connection problems keep a null
  /// statusCode, which the repository reads as "offline".
  Future<Object?> _send(Future<Response<Object?>> Function() call) async {
    try {
      final response = await call();
      return response.data;
    } on DioException catch (e) {
      final body = e.response?.data;
      final err = body is Map<String, dynamic> ? body['error'] : null;
      final message = err is Map<String, dynamic> ? err['message'] as String? : null;
      throw ServerException(statusCode: e.response?.statusCode, message: message);
    }
  }
}
