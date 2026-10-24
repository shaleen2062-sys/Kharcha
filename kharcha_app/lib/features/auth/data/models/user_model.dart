import 'package:firebase_auth/firebase_auth.dart';

import 'package:kharcha_app/features/auth/domain/entities/app_user.dart';

/// Firebase's view of a user, converted to the app's [AppUser].
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.emailVerified = false,
  });

  factory UserModel.fromFirebase(User user) {
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      emailVerified: user.emailVerified,
    );
  }

  final String id;
  final String email;
  final String? displayName;
  final bool emailVerified;

  AppUser toEntity() {
    return AppUser(
      id: id,
      email: email,
      displayName: displayName,
      emailVerified: emailVerified,
    );
  }
}
