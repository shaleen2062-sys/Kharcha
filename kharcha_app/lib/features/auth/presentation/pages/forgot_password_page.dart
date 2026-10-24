import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kharcha_app/core/router/route_names.dart';
import 'package:kharcha_app/core/theme/app_text_styles.dart';
import 'package:kharcha_app/core/utils/validators.dart';
import 'package:kharcha_app/core/widgets/app_button.dart';
import 'package:kharcha_app/core/widgets/app_snack_bar.dart';
import 'package:kharcha_app/core/widgets/app_text_field.dart';
import 'package:kharcha_app/features/auth/presentation/providers/auth_providers.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final sent = await ref.read(authControllerProvider.notifier).sendPasswordReset(_email.text);
    if (sent && mounted) {
      AppSnackBar.success(context, 'If that email has an account, a reset link is on its way.');
      context.go(RoutePaths.login);
    }
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Reset your password', style: AppTextStyles.display.copyWith(fontSize: 30)),
                    const SizedBox(height: 8),
                    Text('Enter your email and we will send you a link to choose a new password.',
                        style: AppTextStyles.caption),
                    const SizedBox(height: 28),
                    AppTextField(
                      controller: _email,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.email],
                      validator: Validators.email,
                      onSubmitted: (_) => _submit(),
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 24),
                    AppButton(label: 'Send reset link', onPressed: _submit, isLoading: isLoading),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
