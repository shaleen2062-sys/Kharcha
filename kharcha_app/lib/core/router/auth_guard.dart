import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kharcha_app/core/router/route_names.dart';
import 'package:kharcha_app/features/auth/domain/entities/app_user.dart';
import 'package:kharcha_app/features/profile/domain/entities/user_profile.dart';

const Set<String> _publicRoutes = {
  RoutePaths.login,
  RoutePaths.signup,
  RoutePaths.forgotPassword,
};

/// Decides where the user should be, based on the auth state and, once signed
/// in, whether they have finished onboarding.
/// Returns null to stay on [location], or the path to redirect to.
///
/// [profile] is optional so the sign-in rules can be used (and tested) alone.
/// A profile that failed to load never blocks the app: the user just gets in.
String? authGuard({
  required AsyncValue<AppUser?> auth,
  required String location,
  AsyncValue<UserProfile>? profile,
}) {
  final isPublic = _publicRoutes.contains(location);

  if (auth is AsyncData<AppUser?>) {
    final signedIn = auth.value != null;
    if (!signedIn) return isPublic ? null : RoutePaths.login;

    // Signed in: wait for the profile, so a new user is not shown Home for a moment.
    if (profile != null && profile.isLoading) {
      return location == RoutePaths.splash ? null : RoutePaths.splash;
    }
    final needsOnboarding = profile != null && profile.hasValue && !profile.requireValue.onboarded;
    if (needsOnboarding) return location == RoutePaths.onboarding ? null : RoutePaths.onboarding;

    if (isPublic || location == RoutePaths.splash || location == RoutePaths.onboarding) return RoutePaths.home;
    return null;
  }

  if (auth is AsyncError<AppUser?>) {
    // The auth stream failed: let the user reach the login screen.
    return isPublic ? null : RoutePaths.login;
  }

  // Still waiting for Firebase to restore the session.
  return location == RoutePaths.splash ? null : RoutePaths.splash;
}
