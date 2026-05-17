import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plans_app/main.dart';
import 'package:plans_app/features/projects/models/project.dart';
import 'package:plans_app/shared/database/database_service.dart';
import 'shared/fake_database_service.dart';

void main() {
  testWidgets('App starts and shows default Inbox view', (WidgetTester tester) async {
    final db = FakeDatabaseService();
    db.seedProject(Project(id: 'default', name: 'Inbox', colorIndex: 0));
    db.seedProject(Project(id: 'work', name: 'Work', colorIndex: 1));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseServiceProvider.overrideWithValue(db),
        ],
        child: const PlansApp(),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Inbox'), findsWidgets);
  });
}
