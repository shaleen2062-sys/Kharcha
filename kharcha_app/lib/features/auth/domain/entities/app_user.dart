/// The signed-in user, as the rest of the app sees them.
/// Pure Dart: no Firebase types here.
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.emailVerified = false,
  });

  final String id;
  final String email;
  final String? displayName;
  final bool emailVerified;

  @override
  bool operator ==(Object other) {
    return other is AppUser &&
        other.id == id &&
        other.email == email &&
        other.displayName == displayName &&
        other.emailVerified == emailVerified;
  }

  @override
  int get hashCode => Object.hash(id, email, displayName, emailVerified);
}
