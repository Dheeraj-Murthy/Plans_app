import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project.dart';
import '../../../shared/database/database_service.dart';

sealed class SidebarSelection {
  const SidebarSelection();
}

class ViewSelection extends SidebarSelection {
  final ViewType view;
  const ViewSelection(this.view);
}

class ProjectSelection extends SidebarSelection {
  final String projectId;
  const ProjectSelection(this.projectId);
}

enum ViewType { inbox, today, completed }

final projectsProvider =
    StateNotifierProvider<ProjectsNotifier, List<Project>>((ref) {
  final db = ref.read(databaseServiceProvider);
  return ProjectsNotifier(db);
});

final sidebarSelectionProvider =
    StateProvider<SidebarSelection>((ref) => const ViewSelection(ViewType.inbox));

class ProjectsNotifier extends StateNotifier<List<Project>> {
  final DatabaseService _db;
  ProjectsNotifier(this._db) : super([]) {
    _load();
  }

  void _load() {
    _db.getProjects().then((rows) {
      state = rows.map((r) => Project.fromMap(r)).toList();
    });
  }
}
