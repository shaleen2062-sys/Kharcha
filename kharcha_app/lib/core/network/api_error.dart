/// The backend's errors look like { "error": { "code": "NOT_FOUND", "message": "Receipt not found" } }.
/// Returns the message (safe to show to the user), or null when the body is not in that shape.
String? apiErrorMessage(Object? body) {
  if (body is Map<String, dynamic>) {
    final err = body['error'];
    if (err is Map<String, dynamic>) return err['message'] as String?;
    final flat = body['message'];
    if (flat is String) return flat;
  }
  return null;
}
