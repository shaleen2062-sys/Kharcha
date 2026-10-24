import 'package:go_router/go_router.dart';

import 'package:kharcha_app/core/router/route_names.dart';
import 'package:kharcha_app/features/scanner/presentation/pages/scan_adjust_page.dart';
import 'package:kharcha_app/features/scanner/presentation/pages/scan_page.dart';
import 'package:kharcha_app/features/scanner/presentation/pages/scan_preview_page.dart';

/// Phones: scan, adjust edges, preview.
List<RouteBase> scannerRoutes() => [
      GoRoute(
        path: RoutePaths.scan,
        name: RouteNames.scan,
        builder: (context, state) => const ScanPage(),
      ),
      GoRoute(
        path: RoutePaths.scanAdjust,
        name: RouteNames.scanAdjust,
        builder: (context, state) => const ScanAdjustPage(),
      ),
      GoRoute(
        path: RoutePaths.scanPreview,
        name: RouteNames.scanPreview,
        builder: (context, state) => const ScanPreviewPage(),
      ),
    ];
