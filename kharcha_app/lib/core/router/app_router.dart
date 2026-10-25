import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kharcha_app/core/router/app_shell.dart';
import 'package:kharcha_app/core/router/auth_guard.dart';
import 'package:kharcha_app/core/router/route_names.dart';
import 'package:kharcha_app/core/router/scanner_routes.dart';
import 'package:kharcha_app/features/alerts/presentation/pages/alerts_page.dart';
import 'package:kharcha_app/features/auth/domain/entities/app_user.dart';
import 'package:kharcha_app/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:kharcha_app/features/auth/presentation/pages/login_page.dart';
import 'package:kharcha_app/features/auth/presentation/pages/signup_page.dart';
import 'package:kharcha_app/features/auth/presentation/pages/splash_page.dart';
import 'package:kharcha_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:kharcha_app/features/budgets/presentation/pages/budgets_page.dart';
import 'package:kharcha_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:kharcha_app/features/insights/presentation/pages/insights_page.dart';
import 'package:kharcha_app/features/profile/domain/entities/user_profile.dart';
import 'package:kharcha_app/features/profile/presentation/pages/onboarding_page.dart';
import 'package:kharcha_app/features/profile/presentation/pages/settings_page.dart';
import 'package:kharcha_app/features/profile/presentation/providers/profile_providers.dart';
import 'package:kharcha_app/features/receipts/presentation/pages/receipt_detail_page.dart';
import 'package:kharcha_app/features/receipts/presentation/pages/receipt_photo_page.dart';
import 'package:kharcha_app/features/receipts/presentation/pages/receipt_edit_page.dart';
import 'package:kharcha_app/features/receipts/presentation/pages/receipts_list_page.dart';
import 'package:kharcha_app/features/receipts/presentation/pages/review_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Re-run the redirect whenever the signed-in user changes.
  final refresh = ValueNotifier<int>(0);
  ref.listen<AsyncValue<AppUser?>>(
    authStateProvider,
    (_, _) => refresh.value++,
  );
  // ...and whenever the profile loads or changes (finishing onboarding sets it).
  ref.listen<AsyncValue<UserProfile>>(
    profileProvider,
    (_, _) => refresh.value++,
  );
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: refresh,
    redirect: (context, state) => authGuard(
      auth: ref.read(authStateProvider),
      profile: ref.read(profileProvider),
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RoutePaths.signup,
        name: RouteNames.signup,
        builder: (context, state) => const SignupPage(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: RoutePaths.alerts,
        name: RouteNames.alerts,
        builder: (context, state) => const AlertsPage(),
      ),
      GoRoute(
        path: RoutePaths.settings,
        name: RouteNames.settings,
        builder: (context, state) => const SettingsPage(),
      ),
      // The four tabs that share the bottom navigation bar.
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.home,
                name: RouteNames.home,
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.review,
                name: RouteNames.review,
                builder: (context, state) => const ReviewPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.budgets,
                name: RouteNames.budgets,
                builder: (context, state) => const BudgetsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.insights,
                name: RouteNames.insights,
                builder: (context, state) => const InsightsPage(),
              ),
            ],
          ),
        ],
      ),
      ...scannerRoutes(),
      GoRoute(
        path: RoutePaths.receipts,
        name: RouteNames.receipts,
        builder: (context, state) => const ReceiptsPage(),
      ),
      GoRoute(
        path: RoutePaths.receiptDetail,
        name: RouteNames.receiptDetail,
        builder: (context, state) =>
            ReceiptDetailPage(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RoutePaths.receiptPhoto,
        name: RouteNames.receiptPhoto,
        builder: (context, state) =>
            ReceiptPhotoPage(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RoutePaths.receiptEdit,
        name: RouteNames.receiptEdit,
        builder: (context, state) =>
            ReceiptEditPage(id: state.pathParameters['id']!),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
