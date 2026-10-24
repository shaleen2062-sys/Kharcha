import 'package:flutter/painting.dart';

import 'package:kharcha_app/core/theme/app_colors.dart';

/// Colours for a spending category: a solid one for bars and a soft pair for chips.
class CategoryStyle {
  const CategoryStyle(this.bar, this.chipBg, this.chipFg);

  final Color bar;
  final Color chipBg;
  final Color chipFg;

  static CategoryStyle get _fallback => CategoryStyle(
        AppColors.isDark ? const Color(0xFF8FA096) : const Color(0xFF6B7A72),
        AppColors.track,
        AppColors.muted,
      );

  static const Map<String, CategoryStyle> _light = {
    'Dining': CategoryStyle(Color(0xFFC2571A), Color(0xFFFBE3D3), Color(0xFF7A3510)),
    'Shopping': CategoryStyle(Color(0xFF8A3F94), Color(0xFFF1E1F2), Color(0xFF5E2A62)),
    'Health': CategoryStyle(Color(0xFFB8336A), Color(0xFFF9DFEA), Color(0xFF7D1F48)),
    'Bills': CategoryStyle(Color(0xFF6B5B1E), Color(0xFFF1EBCB), Color(0xFF4F4210)),
    'Entertainment': CategoryStyle(Color(0xFF3B7E9C), Color(0xFFDDEEF5), Color(0xFF1E5167)),
  };

  static const Map<String, CategoryStyle> _dark = {
    'Dining': CategoryStyle(Color(0xFFE08A52), Color(0xFF3D2516), Color(0xFFF3C3A3)),
    'Shopping': CategoryStyle(Color(0xFFC57BCF), Color(0xFF35203A), Color(0xFFE6C0EB)),
    'Health': CategoryStyle(Color(0xFFE56B9B), Color(0xFF3B1B29), Color(0xFFF3B7CF)),
    'Bills': CategoryStyle(Color(0xFFC9B35A), Color(0xFF332D14), Color(0xFFE8DB9F)),
    'Entertainment': CategoryStyle(Color(0xFF6FB3D1), Color(0xFF17303B), Color(0xFFB4DDEE)),
  };

  static CategoryStyle of(String? category) {
    switch (category) {
      case 'Groceries':
        return CategoryStyle(AppColors.primary, AppColors.primarySoft, AppColors.primarySoftInk);
      case 'Transport':
        return CategoryStyle(AppColors.blue, AppColors.blueSoft, AppColors.blueInk);
    }
    return (AppColors.isDark ? _dark : _light)[category] ?? _fallback;
  }
}
