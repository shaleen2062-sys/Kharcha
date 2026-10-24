import 'package:flutter/material.dart';

import 'package:kharcha_app/core/error/failures.dart';

abstract final class AppSnackBar {
  /// Shows a Failure's message, or a generic one for anything else.
  static void error(BuildContext context, Object error) {
    final message = error is Failure ? error.message : 'Something went wrong. Please try again.';
    _show(context, message);
  }

  static void success(BuildContext context, String message) => _show(context, message);

  static void _show(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
