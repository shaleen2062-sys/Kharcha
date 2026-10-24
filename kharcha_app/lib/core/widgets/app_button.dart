import 'package:flutter/material.dart';

import 'package:kharcha_app/core/theme/app_colors.dart';
import 'package:kharcha_app/core/theme/app_text_styles.dart';

enum AppButtonVariant { filled, outlined }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.filled,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final isFilled = variant == AppButtonVariant.filled;
    final onTap = isLoading ? null : onPressed;

    final child = isLoading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: isFilled ? Colors.white : AppColors.primary,
            ),
          )
        : Text(label);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: isFilled
          ? FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                shape: const StadiumBorder(),
                textStyle: AppTextStyles.button,
              ),
              child: child,
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                shape: const StadiumBorder(),
                foregroundColor: AppColors.ink,
                side: BorderSide(color: AppColors.line),
                textStyle: AppTextStyles.button,
              ),
              child: child,
            ),
    );
  }
}
