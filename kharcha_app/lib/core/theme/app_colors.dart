import 'dart:ui';

/// Colours from the Kharcha design canvas, in a light and a dark set.
///
/// These are getters, not constants: they answer for whichever set is active.
/// [apply] is called by `App` before the widgets are built, and the app rebuilds
/// when the theme changes, so every screen follows. Because they are not
/// constants, a widget that uses one cannot be `const`.
abstract final class AppColors {
  static bool _dark = false;

  static bool get isDark => _dark;

  static void apply(Brightness brightness) =>
      _dark = brightness == Brightness.dark;

  static Color _pick(int light, int dark) => Color(_dark ? dark : light);

  static Color get bg => _pick(0xFFF4F6F2, 0xFF0E1512);
  static Color get card => _pick(0xFFFFFFFF, 0xFF17211C);
  static Color get line => _pick(0xFFDDE3DC, 0xFF2A3730);
  static Color get track => _pick(0xFFE6EBE5, 0xFF26332C);

  /// Hairline between rows inside a card.
  static Color get divider => _pick(0xFFEDF1EC, 0xFF222D27);

  static Color get ink => _pick(0xFF12261F, 0xFFE6EEE9);
  static Color get muted => _pick(0xFF4F6159, 0xFF9DB0A6);

  /// Body text that is a little softer than [ink].
  static Color get body => _pick(0xFF3C4A43, 0xFFC3D1CA);

  static Color get primary => _pick(0xFF0B6B57, 0xFF1A8F78);
  static Color get primarySoft => _pick(0xFFDCEFE8, 0xFF173B33);
  static Color get primarySoftInk => _pick(0xFF0A4D3F, 0xFF8FE0C9);

  static Color get amber => _pick(0xFFD99A1E, 0xFFE0A93B);
  static Color get amberSoft => _pick(0xFFFBEBC5, 0xFF3D2F10);
  static Color get amberInk => _pick(0xFF5C3A00, 0xFFF2CE7E);

  static Color get danger => _pick(0xFFA63A2B, 0xFFE0705F);
  static Color get dangerSoft => _pick(0xFFF7DDD7, 0xFF3F1D18);
  static Color get dangerInk => _pick(0xFF7A241A, 0xFFF3A396);

  static Color get blue => _pick(0xFF2E5AAC, 0xFF7FA6EE);
  static Color get blueSoft => _pick(0xFFDDE7F6, 0xFF1D2B45);
  static Color get blueInk => _pick(0xFF1B3D78, 0xFFB7CDF5);
}
