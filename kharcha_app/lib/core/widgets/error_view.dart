import 'package:flutter/material.dart';

import 'package:kharcha_app/core/theme/app_colors.dart';
import 'package:kharcha_app/core/widgets/app_button.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: AppButton(
                  label: 'Try again',
                  onPressed: onRetry,
                  variant: AppButtonVariant.outlined,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
