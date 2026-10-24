import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin wrapper around connectivity_plus. It tells you whether the device has a
/// network connection, not whether the server is reachable.
class NetworkInfo {
  NetworkInfo(this._connectivity);

  final Connectivity _connectivity;

  Future<bool> get isOnline async => _hasConnection(await _connectivity.checkConnectivity());

  Stream<bool> get onStatusChange => _connectivity.onConnectivityChanged.map(_hasConnection);

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }
}
