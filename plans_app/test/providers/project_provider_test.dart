import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plans_app/features/projects/providers/project_provider.dart';
import 'package:plans_app/shared/database/database_service.dart';
import '../shared/fake_database_service.dart';

ProviderContainer createContainer(DatabaseService db) {
  return ProviderContainer(
    overrides: [
      databaseServiceProvider.overrideWithValue(db),
    ],
  );
}

Future<void> waitForProjects(ProviderContainer c) async {
  c.read(projectsProvider);
  await Future(() {});
  await Future(() {});
}

void main() {
  group('ProjectsNotifier', () {
    test('starts empty with fake DB', () async {
      final db = FakeDatabaseService();
      final container = createContainer(db);
      await waitForProjects(container);
      expect(container.read(projectsProvider), isEmpty);
      container.dispose();
    });

    test('addProject inserts and returns', () async {
      final db = FakeDatabaseService();
      final container = createContainer(db);
      await waitForProjects(container);
      await container.read(projectsProvider.notifier).addProject('Test Project', colorIndex: 3);
      expect(container.read(projectsProvider).length, 1);
      expect(container.read(projectsProvider).last.name, 'Test Project');
      container.dispose();
    });

    test('deleteProject removes project', () async {
      final db = FakeDatabaseService();
      final container = createContainer(db);
      await waitForProjects(container);
      await container.read(projectsProvider.notifier).addProject('To Delete', colorIndex: 0);
      final added = container.read(projectsProvider).first;
      await container.read(projectsProvider.notifier).deleteProject(added.id);
      expect(container.read(projectsProvider), isEmpty);
      container.dispose();
    });

    test('updateProject renames project', () async {
      final db = FakeDatabaseService();
      final container = createContainer(db);
      await waitForProjects(container);
      await container.read(projectsProvider.notifier).addProject('Original', colorIndex: 0);
      final added = container.read(projectsProvider).first;
      await container.read(projectsProvider.notifier).updateProject(added.id, name: 'Renamed', colorIndex: 0);
      expect(container.read(projectsProvider).first.name, 'Renamed');
      container.dispose();
    });
  });

  group('sidebarSelectionProvider', () {
    test('defaults to inbox', () {
      final container = ProviderContainer();
      expect(container.read(sidebarSelectionProvider), const ViewSelection(ViewType.inbox));
      container.dispose();
    });

    test('can switch to project selection', () {
      final container = ProviderContainer();
      container.read(sidebarSelectionProvider.notifier).state = const ProjectSelection('work');
      expect(container.read(sidebarSelectionProvider), const ProjectSelection('work'));
      container.dispose();
    });
  });
}
