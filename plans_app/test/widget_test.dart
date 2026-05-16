import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:plans_app/main.dart';
import 'package:plans_app/shared/database/database_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  testWidgets('App starts and shows default Inbox view', (WidgetTester tester) async {
    final db = DatabaseService(testPath: inMemoryDatabasePath);

    // runAsync lets real async I/O (sqflite FFI) complete — pump() alone won't
    await tester.runAsync(() async {
      await db.database;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseServiceProvider.overrideWithValue(db),
          ],
          child: const PlansApp(),
        ),
      );

      // Allow DB load + provider callbacks to settle
      await Future.delayed(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
    });

    expect(find.text('Inbox'), findsWidgets);
  });
}
