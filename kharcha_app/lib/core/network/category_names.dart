/// The app's screens use eight short category names; the backend's default categories are named a little
/// differently. Everything that crosses the network goes through here, so no screen needs to know.
///
///   app name        backend name
///   Dining      <-> Food & Dining
///   Health      <-> Healthcare
///   Bills       <-> Utilities
///   Other       <-> Other, Uncategorized
///
/// Names that are the same on both sides (Groceries, Transport, Shopping, Entertainment) and custom
/// categories pass through unchanged.
abstract final class CategoryNames {
  static const Map<String, String> _toApi = {
    'Dining': 'Food & Dining',
    'Health': 'Healthcare',
    'Bills': 'Utilities',
  };

  static final Map<String, String> _fromApi = {
    for (final e in _toApi.entries) e.value: e.key,
    'Uncategorized': 'Other',
  };

  /// Backend name for an app name (what to send).
  static String? toApi(String? appName) => appName == null ? null : (_toApi[appName] ?? appName);

  /// App name for a backend name (what was received). Safe to call on a name that is already an app name.
  static String? fromApi(String? apiName) => apiName == null ? null : (_fromApi[apiName] ?? apiName);
}
