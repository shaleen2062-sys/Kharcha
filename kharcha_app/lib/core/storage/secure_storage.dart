import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Small wrapper over the platform keystore, for anything that must not sit in plain files.
/// (Firebase keeps the sign-in token itself; use this for extras such as a PIN or API key.)
class SecureStorage {
  SecureStorage([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<String?> read(String key) => _storage.read(key: key);
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
  Future<void> delete(String key) => _storage.delete(key: key);
  Future<void> clear() => _storage.deleteAll();
}
