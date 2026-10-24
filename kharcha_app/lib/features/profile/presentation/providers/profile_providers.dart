import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/core/usecase/usecase.dart';
import 'package:kharcha_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:kharcha_app/features/profile/di/profile_di.dart';
import 'package:kharcha_app/features/profile/domain/entities/user_profile.dart';

/// The signed-in user's profile. Loads again whenever the signed-in user
/// changes. While signed out it holds a finished profile, so nothing tries to
/// send a signed-out user to onboarding.
class ProfileController extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() async {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const UserProfile(onboarded: true);
    final result = await ref.watch(getProfileUseCaseProvider)(const NoParams());
    final loaded = result.fold((failure) => throw failure, (profile) => profile);
    // First visit: suggest the name they signed up with.
    if (loaded.displayName.isEmpty && (user.displayName ?? '').isNotEmpty) {
      return loaded.copyWith(displayName: user.displayName);
    }
    return loaded;
  }

  /// Saves the profile. Returns the Failure on error, or null on success.
  Future<Failure?> save(UserProfile profile) async {
    final result = await ref.read(saveProfileUseCaseProvider)(profile);
    return result.fold<Failure?>((failure) => failure, (saved) {
      state = AsyncData<UserProfile>(saved);
      return null;
    });
  }
}

final profileProvider = AsyncNotifierProvider<ProfileController, UserProfile>(ProfileController.new);
