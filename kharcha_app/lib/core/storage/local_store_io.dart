import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'package:kharcha_app/core/storage/local_store.dart';

/// Files inside the app's private storage folder (other apps cannot read it).
class FileLocalStore implements LocalStore {
  FileLocalStore([Future<Directory> Function()? baseDir]) : _baseDir = baseDir ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _baseDir;

  Future<String> _root() async => '${(await _baseDir()).path}/kharcha_store';

  Future<File> _file(String key) async {
    checkStoreKey(key);
    return File('${await _root()}/$key');
  }

  @override
  Future<Uint8List?> readBytes(String key) async {
    final file = await _file(key);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  @override
  Future<void> writeBytes(String key, Uint8List bytes) async {
    final file = await _file(key);
    await file.parent.create(recursive: true);
    // Write to a temporary file first so a crash never leaves half a file.
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsBytes(bytes, flush: true);
    await tmp.rename(file.path);
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
    final file = await _file(key);
    if (await file.exists()) await file.delete();
  }

  @override
  Future<List<String>> keys(String prefix) async {
    final root = await _root();
    final slash = prefix.lastIndexOf('/');
    final dirPart = slash < 0 ? '' : prefix.substring(0, slash);
    if (dirPart.isNotEmpty) checkStoreKey(dirPart);
    final dir = Directory(dirPart.isEmpty ? root : '$root/$dirPart');
    if (!await dir.exists()) return [];

    final out = <String>[];
    await for (final entity in dir.list(recursive: true)) {
      if (entity is! File || entity.path.endsWith('.tmp')) continue;
      final key = entity.path.substring(root.length + 1).replaceAll('\\', '/');
      if (key.startsWith(prefix)) out.add(key);
    }
    out.sort();
    return out;
  }
}

LocalStore createLocalStore() => FileLocalStore();
