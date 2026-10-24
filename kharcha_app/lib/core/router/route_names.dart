/// URL paths used by go_router.
abstract final class RoutePaths {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/';
  static const String scan = '/scan';
  static const String scanAdjust = '/scan/adjust';
  static const String scanPreview = '/scan/preview';
  static const String review = '/review';
  static const String budgets = '/budgets';
  static const String insights = '/insights';
  static const String onboarding = '/onboarding';
  static const String settings = '/settings';
  static const String alerts = '/alerts';
  static const String receipts = '/receipts';
  static const String receiptDetail = '/receipts/:id';
  static String receiptDetailFor(String id) => '/receipts/$id';
  static const String receiptEdit = '/receipts/:id/edit';
  static String receiptEditFor(String id) => '/receipts/$id/edit';
  static const String receiptPhoto = '/receipts/:id/photo';
  static String receiptPhotoFor(String id) => '/receipts/$id/photo';
}

/// Route names, for context.goNamed(...).
abstract final class RouteNames {
  static const String splash = 'splash';
  static const String login = 'login';
  static const String signup = 'signup';
  static const String forgotPassword = 'forgot-password';
  static const String home = 'home';
  static const String scan = 'scan';
  static const String scanAdjust = 'scan-adjust';
  static const String scanPreview = 'scan-preview';
  static const String review = 'review';
  static const String budgets = 'budgets';
  static const String insights = 'insights';
  static const String onboarding = 'onboarding';
  static const String settings = 'settings';
  static const String alerts = 'alerts';
  static const String receipts = 'receipts';
  static const String receiptDetail = 'receipt-detail';
  static const String receiptEdit = 'receipt-edit';
  static const String receiptPhoto = 'receipt-photo';
}
