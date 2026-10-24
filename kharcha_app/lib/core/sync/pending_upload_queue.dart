import 'dart:typed_data';

import 'package:kharcha_app/core/storage/local_store.dart';

/// Photos waiting for the internet, kept on the phone per signed-in user.
/// Each is a JPEG named by its id; ids sort oldest first.
class PendingUploads {
  PendingUploads(this._store, this._uid);

  final LocalStore _store;
  final String? Function() _uid;

  /// More than this and `add` refuses, so the phone's storage cannot fill up.
  static const int maxPending = 20;

  /// A fresh id. Also used as the Idempotency-Key for the first live attempt.
  String newId() => DateTime.now().microsecondsSinceEpoch.toString().padLeft(20, '0');

  String? _dir() {
    final uid = _uid();
    return uid == null ? null : 'uploads/$uid/';
  }

  /// Saves the photo. Returns its id, or null when signed out or the queue is full.
  Future<String?> add(Uint8List jpeg, {String? id}) async {
    final dir = _dir();
    if (dir == null) return null;
    if ((await ids()).length >= maxPending) return null;
    final key = id ?? newId();
    try {
      await _store.writeBytes('$dir$key.jpg', jpeg);
      return key;
    } catch (_) {
      return null;
    }
  }

  /// Ids of waiting photos, oldest first.
  Future<List<String>> ids() async {
    final dir = _dir();
    if (dir == null) return [];
    try {
      final keys = await _store.keys(dir);
      return keys
          .where((k) => k.endsWith('.jpg'))
          .map((k) => k.substring(dir.length, k.length - 4))
          .toList()
        ..sort();
    } catch (_) {
      return [];
    }
  }

  Future<Uint8List?> read(String id) async {
    final dir = _dir();
    if (dir == null) return null;
    try {
      return await _store.readBytes('$dir$id.jpg');
    } catch (_) {
      return null;
    }
  }

  Future<void> remove(String id) async {
    final dir = _dir();
    if (dir == null) return;
    try {
      await _store.delete('$dir$id.jpg');
    } catch (_) {}
  }
}
