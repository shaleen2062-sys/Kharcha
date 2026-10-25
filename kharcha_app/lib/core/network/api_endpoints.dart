/// Backend paths, relative to Env.apiBaseUrl. The Express app mounts everything
/// that needs sign-in under /api. The contract is backend/docs/api-contract.md.
abstract final class ApiEndpoints {
  static const String health = '/api/health';
  static const String me = '/api/users/me';
  static const String profile = '/api/users/me';
  static const String categories = '/api/categories';
  static const String alerts = '/api/alerts';
  static const String alertsReadAll = '/api/alerts/read-all';
  static String alertRead(String id) => '/api/alerts/$id/read';
  static const String receipts = '/api/receipts';
  static const String rawReceipts = '/api/receipts/raw';
  static String receipt(String id) => '/api/receipts/$id';
  static const String dashboardSummary = '/api/dashboard/summary';
  static const String dashboardTrend = '/api/dashboard/trend';
  static const String budgets = '/api/budgets';
  /// Budgets are keyed by the backend category id (see CategoryDirectory).
  static String budget(String categoryId) => '/api/budgets/${Uri.encodeComponent(categoryId)}';
}
