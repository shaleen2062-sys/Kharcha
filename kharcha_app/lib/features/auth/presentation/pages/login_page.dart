import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kharcha_app/core/router/route_names.dart';
import 'package:kharcha_app/core/theme/app_colors.dart';
import 'package:kharcha_app/core/theme/app_text_styles.dart';
import 'package:kharcha_app/core/utils/validators.dart';
import 'package:kharcha_app/core/widgets/app_button.dart';
import 'package:kharcha_app/core/widgets/app_snack_bar.dart';
import 'package:kharcha_app/core/widgets/app_text_field.dart';
import 'package:kharcha_app/core/widgets/offline_banner.dart';
import 'package:kharcha_app/features/auth/presentation/providers/auth_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // On success the auth guard moves the user to the home screen.
    await ref
        .read(authControllerProvider.notifier)
        .signIn(_email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      if (next is AsyncError<void>) AppSnackBar.error(context, next.error);
    });
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const OfflineBanner(
                        message:
                            'You are offline. Signing in needs a connection.',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kharcha',
                        style: AppTextStyles.display.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Photograph a receipt and see where your money goes.',
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: 32),
                      AppTextField(
                        controller: _email,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        validator: Validators.email,
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _password,
                        label: 'Password',
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        validator: (value) =>
                            Validators.required(value, field: 'Password'),
                        onSubmitted: (_) => _submit(),
                        enabled: !isLoading,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: isLoading
                              ? null
                              : () => context.go(RoutePaths.forgotPassword),
                          child: const Text('Forgot password?'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      AppButton(
                        label: 'Sign in',
                        onPressed: _submit,
                        isLoading: isLoading,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: isLoading
                            ? null
                            : () => ref
                                  .read(authControllerProvider.notifier)
                                  .signInWithGoogle(),
                        icon: const Icon(Icons.account_circle_outlined),
                        label: const Text('Continue with Google'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: const StadiumBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('New to Kharcha?', style: AppTextStyles.caption),
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () => context.go(RoutePaths.signup),
                            child: const Text('Create an account'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
