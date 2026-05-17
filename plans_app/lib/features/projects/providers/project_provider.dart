import 'package:flutter/foundation.dart';
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
    _db.getProjects().then((projects) {
      state = projects;
    }).catchError((e) {
      debugPrint('ProjectsNotifier._load failed: $e');
    });
  }

  Future<void> addProject(String name, {required int colorIndex}) async {
    final project = await _db.insertProject(name: name, colorIndex: colorIndex);
    state = [...state, project];
  }

  Future<void> updateProject(String id, {required String name}) async {
    final idx = state.indexWhere((p) => p.id == id);
    if (idx < 0) return;
    final updated = state[idx].copyWith(name: name);
    await _db.updateProject(updated);
    final list = [...state];
    list[idx] = updated;
    state = list;
  }

  Future<void> deleteProject(String id) async {
    await _db.deleteProject(id);
    state = state.where((p) => p.id != id).toList();
  }
}
