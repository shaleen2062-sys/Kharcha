// The scanner needs a camera and OpenCV, which only exist on phones.
// On web this exports an empty list, so those packages are never compiled in.
export 'package:kharcha_app/core/router/scanner_routes_stub.dart'
    if (dart.library.io) 'package:kharcha_app/core/router/scanner_routes_native.dart';
