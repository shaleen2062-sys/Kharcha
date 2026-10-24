/// Form validators. Each returns an error message, or null when the value is fine.
abstract final class Validators {
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter your email';
    if (!_emailPattern.hasMatch(text)) return 'Enter a valid email address';
    return null;
  }

  /// Firebase requires at least 6 characters.
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Enter a password';
    if (value.length < 6) return 'Use at least 6 characters';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }
}
