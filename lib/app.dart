import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/widgets/call_listener_wrapper.dart';
import 'routes/app_router.dart';
import 'ui/theme/app_theme.dart';
import 'state/theme_provider.dart' as theme_provider;

class CarpoolApp extends ConsumerWidget {
  const CarpoolApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(theme_provider.themeProvider);

    // Convert custom ThemeMode to Material ThemeMode
    final materialThemeMode = themeMode == theme_provider.ThemeMode.light
        ? ThemeMode.light
        : themeMode == theme_provider.ThemeMode.dark
        ? ThemeMode.dark
        : ThemeMode.system;

    return MaterialApp.router(
      title: 'EzRide',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: materialThemeMode,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        return CallListenerWrapper(
          navigatorKey: rootNavigatorKey,
          child: child!,
        );
      },
    );
  }
}
