import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kharcha_app/core/router/route_names.dart';
import 'package:kharcha_app/core/theme/app_text_styles.dart';
import 'package:kharcha_app/core/utils/validators.dart';
import 'package:kharcha_app/core/widgets/app_button.dart';
import 'package:kharcha_app/core/widgets/app_snack_bar.dart';
import 'package:kharcha_app/core/widgets/app_text_field.dart';
import 'package:kharcha_app/core/widgets/offline_banner.dart';
import 'package:kharcha_app/features/auth/presentation/providers/auth_providers.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // On success Firebase signs the user in, and the auth guard opens the home screen.
    await ref
        .read(authControllerProvider.notifier)
        .signUp(_email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      if (next is AsyncError<void>) AppSnackBar.error(context, next.error);
    });
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to sign in',
          icon: const Icon(Icons.arrow_back),
          onPressed: isLoading ? null : () => context.go(RoutePaths.login),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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
                            'You are offline. Creating an account needs a connection.',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your account',
                        style: AppTextStyles.display.copyWith(fontSize: 30),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'It takes under a minute.',
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: 28),
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
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: Validators.password,
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _confirm,
                        label: 'Confirm password',
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                        validator: (value) =>
                            Validators.confirmPassword(value, _password.text),
                        onSubmitted: (_) => _submit(),
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        label: 'Create account',
                        onPressed: _submit,
                        isLoading: isLoading,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: AppTextStyles.caption,
                          ),
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () => context.go(RoutePaths.login),
                            child: const Text('Sign in'),
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
