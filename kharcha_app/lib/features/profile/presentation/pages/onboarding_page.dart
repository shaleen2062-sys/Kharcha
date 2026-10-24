import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kharcha_app/core/router/route_names.dart';
import 'package:kharcha_app/core/theme/app_colors.dart';
import 'package:kharcha_app/core/theme/app_text_styles.dart';
import 'package:kharcha_app/core/widgets/app_button.dart';
import 'package:kharcha_app/core/widgets/app_snack_bar.dart';
import 'package:kharcha_app/features/profile/presentation/providers/onboarding_draft.dart';
import 'package:kharcha_app/features/profile/presentation/widgets/profile_fields.dart';

/// Shown once to a new user: name and income, category budgets, alerts.
/// Nothing is saved until the last step, so backing out loses nothing.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _Step {
  const _Step(this.title, this.subtitle, this.body);
  final String title;
  final String subtitle;
  final Widget body;
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  int _index = 0;
  bool _saving = false;

  static const _steps = <_Step>[
    _Step(
      'Welcome to Kharcha',
      'Tell us your name and, if you like, what you earn. Income is optional and helps us suggest budgets.',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [ProfileFields(), SizedBox(height: 16), IncomeFields()],
      ),
    ),
    _Step(
      'Monthly budgets',
      'Pick the categories you want to keep an eye on. You can change these any time.',
      BudgetFields(),
    ),
    _Step(
      'Alerts',
      'We will tell you before a budget runs out.',
      AlertFields(),
    ),
  ];

  bool get _isLast => _index == _steps.length - 1;

  void _next() {
    if (_index == 0 &&
        ref.read(onboardingDraftProvider).profile.displayName.trim().isEmpty) {
      AppSnackBar.success(context, 'Please enter your name to continue.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _index++);
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final failure = await ref.read(onboardingDraftProvider.notifier).save();
    if (!mounted) return;
    setState(() => _saving = false);
    if (failure != null) {
      AppSnackBar.error(context, failure);
      return;
    }
    context.go(RoutePaths.home);
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_index];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  for (var i = 0; i < _steps.length; i++)
                    Expanded(
                      child: Container(
                        height: 5,
                        margin: EdgeInsets.only(
                          right: i == _steps.length - 1 ? 0 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: i <= _index
                              ? AppColors.primary
                              : AppColors.track,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: AppTextStyles.heading.copyWith(fontSize: 26),
                    ),
                    const SizedBox(height: 6),
                    Text(step.subtitle, style: AppTextStyles.caption),
                    const SizedBox(height: 24),
                    step.body,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  if (_index > 0) ...[
                    Expanded(
                      child: AppButton(
                        label: 'Back',
                        variant: AppButtonVariant.outlined,
                        onPressed: _saving
                            ? null
                            : () => setState(() => _index--),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label: _isLast ? 'Finish' : 'Continue',
                      isLoading: _saving,
                      onPressed: _isLast ? _finish : _next,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
