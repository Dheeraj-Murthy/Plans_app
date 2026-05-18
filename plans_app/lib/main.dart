import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:plans_app/src/rust/api.dart' as rust_api;
import 'package:plans_app/src/rust/frb_generated.dart';
import 'theme/app_theme.dart';
import 'routing/app_router.dart';
import 'shared/database/database_service.dart';
import 'shared/notifications/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await RustLib.init(
    externalLibrary: ExternalLibrary.open(
      '@rpath/plans_core.framework/plans_core',
    ),
  );

  final dir = await getApplicationDocumentsDirectory();
  await rust_api.initDatabase(path: '${dir.path}/plans.db');
  await NotificationService.init();

  final db = DatabaseService();

  runApp(
    ProviderScope(
      overrides: [
        databaseServiceProvider.overrideWithValue(db),
      ],
      child: PlansApp(),
    ),
  );
}

class PlansApp extends ConsumerWidget {
  const PlansApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = appRouter;
    return MaterialApp.router(
      title: 'Plans',
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
