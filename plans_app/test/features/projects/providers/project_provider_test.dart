import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plans_app/features/projects/providers/project_provider.dart';
import 'package:plans_app/shared/database/database_service.dart';
import '../../../shared/fake_database_service.dart';

void main() {
  group('ProjectsNotifier', () {
    test('updateProject changes colorIndex', () async {
      final container = ProviderContainer(
        overrides: [
          databaseServiceProvider.overrideWithValue(FakeDatabaseService()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(projectsProvider.notifier);
      await notifier.addProject('Test', colorIndex: 0);

      final project = container.read(projectsProvider).first;
      await notifier.updateProject(project.id, name: project.name, colorIndex: 2);

      final updated = container.read(projectsProvider).first;
      expect(updated.colorIndex, 2);
    });
  });
}
