import 'dart:convert';

import 'package:kharcha_app/core/storage/local_store.dart';

/// Remembers the last good server answer per signed-in user, so screens still
/// show something with no internet. Best effort: any problem reading or
/// writing is swallowed, because the cache must never break the app.
class JsonCache {
  JsonCache(this._store, this._uid);

  final LocalStore _store;

  /// Returns the signed-in user's id, or null when signed out (then nothing is cached).
  final String? Function() _uid;

  String? _key(String name) {
    final uid = _uid();
    return uid == null ? null : 'cache/$uid/$name.json';
  }

  Future<Object?> read(String name) async {
    final key = _key(name);
    if (key == null) return null;
    try {
      final text = await _store.readText(key);
      return text == null ? null : jsonDecode(text);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String name, Object value) async {
    final key = _key(name);
    if (key == null) return;
    try {
      await _store.writeText(key, jsonEncode(value));
    } catch (_) {}
  }

  /// Forgets everything cached for the signed-in user (called on sign out).
  Future<void> clear() async {
    final uid = _uid();
    if (uid == null) return;
    try {
      for (final key in await _store.keys('cache/$uid/')) {
        await _store.delete(key);
      }
    } catch (_) {}
  }
}
