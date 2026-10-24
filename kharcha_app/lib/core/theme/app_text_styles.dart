import 'package:flutter/painting.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kharcha_app/core/theme/app_colors.dart';

/// Headings use Bricolage Grotesque, body text uses Figtree (same as the design).
abstract final class AppTextStyles {
  static TextStyle get display => GoogleFonts.bricolageGrotesque(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
        height: 1.1,
      );

  static TextStyle get heading => GoogleFonts.bricolageGrotesque(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      );

  static TextStyle get subheading => GoogleFonts.bricolageGrotesque(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      );

  static TextStyle get body => GoogleFonts.figtree(
        fontSize: 15,
        color: AppColors.ink,
      );

  static TextStyle get caption => GoogleFonts.figtree(
        fontSize: 14,
        color: AppColors.muted,
      );

  static TextStyle get button => GoogleFonts.figtree(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );
}
