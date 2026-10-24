import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kharcha_app/core/router/route_names.dart';
import 'package:kharcha_app/core/theme/app_colors.dart';

/// The round white back button used in the design. Goes back, or home when
/// there is nothing to go back to (for example after a refresh on web).
class CircleBackButton extends StatelessWidget {
  const CircleBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        button: true,
        label: 'Back',
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => context.canPop() ? context.pop() : context.go(RoutePaths.home),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.card,
              border: Border.all(color: AppColors.line),
            ),
            child: Icon(Icons.chevron_left, size: 26, color: AppColors.ink),
          ),
        ),
      ),
    );
  }
}

/// A round 44px icon button, like the bell and the plus in the design.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  /// Green with a white icon (the plus) instead of white with a border (the bell).
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? AppColors.primary : AppColors.card,
            border: filled ? null : Border.all(color: AppColors.line),
          ),
          child: Icon(icon, size: 22, color: filled ? Colors.white : AppColors.ink),
        ),
      ),
    );
  }
}
