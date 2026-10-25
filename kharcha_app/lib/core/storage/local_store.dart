import 'dart:typed_data';

/// Tiny key-value store for files on the device. Keys look like paths
/// (`cache/<uid>/receipts.json`). Two implementations: files on phones
/// (`local_store_io.dart`) and memory on web and in tests (`local_store_stub.dart`).
abstract interface class LocalStore {
  Future<Uint8List?> readBytes(String key);
  Future<void> writeBytes(String key, Uint8List bytes);
  Future<String?> readText(String key);
  Future<void> writeText(String key, String value);
  Future<void> delete(String key);

  /// Every key that starts with [prefix] (for example `uploads/<uid>/`).
  Future<List<String>> keys(String prefix);
}

final RegExp _validKey = RegExp(r'^[A-Za-z0-9._\-/]+$');

/// Keys become file paths, so keep them boring: letters, digits, dot, dash,
/// underscore and slash only, no leading slash, no ".." segment.
bool isValidStoreKey(String key) {
  if (key.isEmpty || key.startsWith('/') || !_validKey.hasMatch(key)) {
    return false;
  }
  return !key.split('/').any((part) => part == '..' || part.isEmpty);
}

void checkStoreKey(String key) {
  if (!isValidStoreKey(key)) {
    throw ArgumentError.value(key, 'key', 'Not a valid store key');
  }
}
