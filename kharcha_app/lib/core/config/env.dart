/// Build-time settings. Override with --dart-define, for example:
///   flutter run --dart-define=API_BASE_URL=https://your-api.example.com
abstract final class Env {
  /// Build channel used for diagnostics and release configuration.
  ///   flutter build apk --release --dart-define=APP_ENV=production
  static const bool isReleaseBuild = bool.fromEnvironment('dart.vm.product');

  static const String appEnvironment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: isReleaseBuild ? 'production' : 'development',
  );

  static bool get isProduction =>
      isReleaseBuild || appEnvironment == 'production';

  /// While the backend is not ready the app runs on built-in sample data, so
  /// every screen can be seen and used. Switch to the real API with:
  ///   flutter run --dart-define=DEMO_DATA=false
  static const bool useDemoData = bool.fromEnvironment(
    'DEMO_DATA',
    defaultValue: !isReleaseBuild,
  );

  /// Demo mode only: start as a user who already finished onboarding, so the
  /// onboarding screens are skipped while you work on other screens.
  ///   flutter run --dart-define=DEMO_ONBOARDED=true
  static const bool demoOnboarded = bool.fromEnvironment(
    'DEMO_ONBOARDED',
    defaultValue: false,
  );

  /// Talk to a backend running with AUTH_MODE=dev: every request carries this token instead of the
  /// Firebase one. You still sign in with Firebase to get past the login screen.
  ///   flutter run --dart-define=DEMO_DATA=false --dart-define=DEV_AUTH_TOKEN=dev:demo
  static const String devAuthToken = String.fromEnvironment('DEV_AUTH_TOKEN');

  /// 10.0.2.2 is how the Android emulator reaches the host machine's localhost.
  /// A real phone cannot use it: point this at your deployed backend instead.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: isReleaseBuild ? '' : 'http://10.0.2.2:4000',
  );

  /// A production build must be given a real HTTPS API endpoint rather than
  /// accidentally shipping the emulator-only development default.
  static void validate() {
    if (!isProduction) return;
    if (useDemoData) {
      throw StateError('Production builds cannot use DEMO_DATA=true.');
    }
    if (devAuthToken.isNotEmpty) {
      throw StateError('Production builds cannot use DEV_AUTH_TOKEN.');
    }
    if (apiBaseUrl.isEmpty) {
      throw StateError(
        'Production builds require --dart-define=API_BASE_URL=https://...',
      );
    }
    if (apiBaseUrl.startsWith('http://10.0.2.2') ||
        apiBaseUrl.startsWith('http://localhost') ||
        apiBaseUrl.startsWith('http://127.0.0.1')) {
      throw StateError(
        'Production builds require --dart-define=API_BASE_URL=https://...',
      );
    }
    if (!apiBaseUrl.startsWith('https://')) {
      throw StateError('Production API_BASE_URL must use HTTPS.');
    }
  }
}
