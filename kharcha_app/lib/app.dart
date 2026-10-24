import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kharcha_app/core/router/app_router.dart';
import 'package:kharcha_app/core/theme/app_colors.dart';
import 'package:kharcha_app/core/theme/app_theme.dart';
import 'package:kharcha_app/core/theme/theme_mode_provider.dart';
import 'package:kharcha_app/features/receipts/presentation/widgets/upload_sync_host.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// The phone switched between light and dark: matters when the choice is "system".
  @override
  void didChangePlatformBrightness() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final mode = ref.watch(themeModeProvider);
    // Work out light or dark here, set the colours, then build the themes from them.
    final platform =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final brightness = switch (mode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => platform,
    };
    AppColors.apply(brightness);
    final theme = AppTheme.of(brightness);

    return MaterialApp.router(
      title: 'Kharcha',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.light, // the theme above already is the right one
      routerConfig: router,
      builder: (context, child) => KeyedSubtree(
        // A new key when the look changes rebuilds every screen with the new colours.
        key: ValueKey(brightness),
        child: UploadSyncHost(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
