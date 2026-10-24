import 'package:flutter/material.dart';

import 'package:kharcha_app/core/theme/app_colors.dart';
import 'package:kharcha_app/core/theme/app_text_styles.dart';
import 'package:kharcha_app/core/widgets/loading_view.dart';

/// Shown for a moment at startup while Firebase restores the saved session.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Kharcha', style: AppTextStyles.display.copyWith(color: AppColors.primary)),
          const SizedBox(height: 24),
          const SizedBox(height: 40, child: LoadingView()),
        ],
      ),
    );
  }
}
