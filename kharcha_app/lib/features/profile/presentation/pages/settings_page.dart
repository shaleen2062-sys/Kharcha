import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kharcha_app/core/di/storage_providers.dart';
import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/core/theme/app_colors.dart';
import 'package:kharcha_app/core/theme/app_text_styles.dart';
import 'package:kharcha_app/core/theme/theme_mode_provider.dart';
import 'package:kharcha_app/core/widgets/app_button.dart';
import 'package:kharcha_app/core/widgets/app_snack_bar.dart';
import 'package:kharcha_app/core/widgets/error_view.dart';
import 'package:kharcha_app/core/widgets/loading_view.dart';
import 'package:kharcha_app/core/widgets/screen_header.dart';
import 'package:kharcha_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:kharcha_app/features/budgets/presentation/providers/budgets_providers.dart';
import 'package:kharcha_app/features/profile/presentation/providers/onboarding_draft.dart';
import 'package:kharcha_app/features/profile/presentation/providers/profile_providers.dart';
import 'package:kharcha_app/features/profile/presentation/widgets/profile_fields.dart';
import 'package:kharcha_app/features/receipts/presentation/providers/receipts_providers.dart';

/// Change the answers from onboarding: profile, income, budgets and alerts. Sign out lives at the bottom.
/// Budget changes apply from this month on; earlier months keep their limits.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _requested = false;
  bool _ready = false;
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    final failure = await ref.read(onboardingDraftProvider.notifier).save();
    if (!mounted) return;
    setState(() => _saving = false);
    if (failure != null) {
      AppSnackBar.error(context, failure);
    } else {
      AppSnackBar.success(
        context,
        'Saved. Budget changes apply from this month on.',
      );
    }
  }

  Future<void> _signOut() async {
    final waiting = ref.read(pendingCountProvider);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: Text(
          waiting > 0
              ? '$waiting receipt${waiting == 1 ? '' : 's'} still waiting to upload. '
                    'They stay on this phone and upload after you sign in again.'
              : 'You will need to sign in again to see your receipts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    // Forget the saved copy of this user's data before leaving.
    await ref.read(jsonCacheProvider).clear();
    await ref.read(authControllerProvider.notifier).signOut();
  }

  Widget _section(String title, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.subheading),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final budgets = ref.watch(budgetsProvider);

    // Fill the form once, when both the profile and the budgets have arrived.
    if (!_requested && profile.hasValue && budgets.hasValue) {
      _requested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(onboardingDraftProvider.notifier)
            .load(profile.requireValue, budgets.requireValue);
        setState(() => _ready = true);
      });
    }

    Widget body;
    final failed = (profile.hasError && !profile.hasValue)
        ? profile.error
        : (budgets.hasError && !budgets.hasValue ? budgets.error : null);
    if (failed != null) {
      body = ErrorView(
        message: failed is Failure
            ? failed.message
            : 'Could not load your settings.',
        onRetry: () {
          ref.invalidate(profileProvider);
          ref.invalidate(budgetsProvider);
        },
      );
    } else if (!_ready) {
      body = const LoadingView();
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          _section('Profile', const ProfileFields()),
          _section('Income', const IncomeFields()),
          _section('Category budgets', const BudgetFields()),
          _section('Alerts', const AlertFields()),
          _section('Appearance', const _AppearanceField()),
          AppButton(
            label: 'Save changes',
            isLoading: _saving,
            onPressed: _save,
          ),
          const SizedBox(height: 28),
          Divider(color: AppColors.divider),
          const SizedBox(height: 16),
          _section(
            'Account',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ref.watch(authStateProvider).value?.email != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Signed in as ${ref.watch(authStateProvider).value!.email}',
                      style: AppTextStyles.caption,
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.dangerInk,
                    minimumSize: const Size.fromHeight(52),
                    side: BorderSide(color: AppColors.dangerInk),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 64,
        leading: const Padding(
          padding: EdgeInsets.only(left: 20),
          child: CircleBackButton(),
        ),
        title: const Text('Profile and settings'),
      ),
      // Keep the last buttons clear of the gesture bar / navigation buttons (top is already handled by the app bar).
      body: SafeArea(top: false, child: body),
    );
  }
}

/// Light, dark or follow the phone. Applies at once and is remembered on this device.
class _AppearanceField extends ConsumerWidget {
  const _AppearanceField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return SegmentedButton<ThemeMode>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: ThemeMode.system,
          label: Text('System'),
          icon: Icon(Icons.brightness_auto_outlined),
        ),
        ButtonSegment(
          value: ThemeMode.light,
          label: Text('Light'),
          icon: Icon(Icons.light_mode_outlined),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          label: Text('Dark'),
          icon: Icon(Icons.dark_mode_outlined),
        ),
      ],
      selected: {mode},
      onSelectionChanged: (s) =>
          ref.read(themeModeProvider.notifier).set(s.first),
    );
  }
}
