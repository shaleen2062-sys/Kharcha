/// Returned from repositories inside an Either. The message is safe to show
/// to the user.
abstract class Failure {
  const Failure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType($message)';
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {this.code});

  final String? code;
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'No internet connection. Check your network and try again.',
  ]);
}

class ServerFailure extends Failure {
  /// A failure with a message for the user. Dart cannot mix optional positional and named parameters in one
  /// constructor, so the message is required here and [ServerFailure.generic] covers "no message".
  const ServerFailure(super.message, {this.statusCode});

  /// The standard message, for when the server gave none.
  const ServerFailure.generic({this.statusCode}) : super(defaultMessage);

  static const String defaultMessage =
      'The server had a problem. Please try again.';

  /// HTTP status from the server, when there was one.
  final int? statusCode;
}

class UnknownFailure extends Failure {
  const UnknownFailure([
    super.message = 'Something went wrong. Please try again.',
  ]);
}
