import 'package:go_router/go_router.dart';
import '../shell/platform_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const PlatformAdaptiveShell(),
    ),
  ],
);
