/// Build-time settings. Override with --dart-define, for example:
///   flutter run --dart-define=API_BASE_URL=https://your-api.example.com
abstract final class Env {
  /// While the backend is not ready the app runs on built-in sample data, so
  /// every screen can be seen and used. Switch to the real API with:
  ///   flutter run --dart-define=DEMO_DATA=false
  static const bool useDemoData = bool.fromEnvironment('DEMO_DATA', defaultValue: true);

  /// Demo mode only: start as a user who already finished onboarding, so the
  /// onboarding screens are skipped while you work on other screens.
  ///   flutter run --dart-define=DEMO_ONBOARDED=true
  static const bool demoOnboarded = bool.fromEnvironment('DEMO_ONBOARDED', defaultValue: false);

  /// Talk to a backend running with AUTH_MODE=dev: every request carries this token instead of the
  /// Firebase one. You still sign in with Firebase to get past the login screen.
  ///   flutter run --dart-define=DEMO_DATA=false --dart-define=DEV_AUTH_TOKEN=dev:demo
  static const String devAuthToken = String.fromEnvironment('DEV_AUTH_TOKEN');

  /// 10.0.2.2 is how the Android emulator reaches the host machine's localhost.
  /// A real phone cannot use it: point this at your deployed backend instead.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:4000',
  );
}
