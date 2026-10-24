/// Thrown by the data layer (datasources). Repositories catch these and turn
/// them into Failures, so nothing above the data layer ever sees an exception.
class AuthException implements Exception {
  const AuthException({required this.code, this.message});

  /// Firebase error code, for example `wrong-password`.
  final String code;
  final String? message;

  @override
  String toString() => 'AuthException($code, $message)';
}

class ServerException implements Exception {
  const ServerException({this.statusCode, this.message});

  final int? statusCode;
  final String? message;

  @override
  String toString() => 'ServerException($statusCode, $message)';
}
