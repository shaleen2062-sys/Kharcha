// Picks the right store at compile time: files on phones, memory on web.
export 'package:kharcha_app/core/storage/local_store_stub.dart'
    if (dart.library.io) 'package:kharcha_app/core/storage/local_store_io.dart'
    show createLocalStore;
