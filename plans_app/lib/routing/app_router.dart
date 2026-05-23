import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../shell/platform_shell.dart';
import '../shared/sync/sync_settings_screen.dart';

GoRouter createRouter(GlobalKey<NavigatorState> navigatorKey) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const PlatformAdaptiveShell(),
      ),
      GoRoute(
        path: '/sync',
        builder: (context, state) => const SyncSettingsScreen(),
      ),
    ],
  );
}
