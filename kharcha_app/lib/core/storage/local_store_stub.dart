import 'dart:convert';
import 'dart:typed_data';

import 'package:kharcha_app/core/storage/local_store.dart';

/// In memory. Used on web (nothing is kept after a reload) and in tests.
class InMemoryLocalStore implements LocalStore {
  final Map<String, Uint8List> _data = {};

  @override
  Future<Uint8List?> readBytes(String key) async {
    checkStoreKey(key);
    return _data[key];
  }

  @override
  Future<void> writeBytes(String key, Uint8List bytes) async {
    checkStoreKey(key);
    _data[key] = Uint8List.fromList(bytes);
  }

  @override
  Future<String?> readText(String key) async {
    final bytes = await readBytes(key);
    return bytes == null ? null : utf8.decode(bytes);
  }

  @override
  Future<void> writeText(String key, String value) => writeBytes(key, Uint8List.fromList(utf8.encode(value)));

  @override
  Future<void> delete(String key) async {
    checkStoreKey(key);
    _data.remove(key);
  }

  @override
  Future<List<String>> keys(String prefix) async => _data.keys.where((k) => k.startsWith(prefix)).toList()..sort();
}

LocalStore createLocalStore() => InMemoryLocalStore();
