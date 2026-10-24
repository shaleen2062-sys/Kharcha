import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kharcha_app/core/theme/app_colors.dart';

abstract final class AppTheme {
  /// Call after [AppColors.apply] for the same brightness: the colours below are read now.
  static ThemeData of(Brightness brightness) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: brightness,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          surface: AppColors.card,
          onSurface: AppColors.ink,
          error: AppColors.danger,
          outline: AppColors.line,
        );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
    );
    final textTheme = GoogleFonts.figtreeTextTheme(
      base.textTheme,
    ).apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleSpacing: 0,
        titleTextStyle: GoogleFonts.bricolageGrotesque(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: _border(AppColors.line),
        enabledBorder: _border(AppColors.line),
        focusedBorder: _border(AppColors.primary, width: 2),
        errorBorder: _border(AppColors.danger),
        focusedErrorBorder: _border(AppColors.danger, width: 2),
      ),
      // Without this, an OFF switch has a pale thumb on a pale track (both come from the very light `outline`
      // colour above) and looks like one grey blob. Off = dark thumb with an outlined track; on = white thumb on green.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return AppColors.line;
          return states.contains(WidgetState.selected)
              ? Colors.white
              : AppColors.muted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          final on = states.contains(WidgetState.selected);
          if (states.contains(WidgetState.disabled)) return AppColors.track;
          return on ? AppColors.primary : AppColors.track;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.transparent;
          return states.contains(WidgetState.disabled)
              ? AppColors.line
              : AppColors.muted;
        }),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      dividerColor: AppColors.line,
      canvasColor: AppColors.card,
      dialogTheme: DialogThemeData(backgroundColor: AppColors.card),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: AppColors.card),
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
