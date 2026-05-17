import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../../projects/providers/project_provider.dart';
import '../../../shared/database/database_service.dart';

final tasksProvider =
    StateNotifierProvider<TasksNotifier, List<Task>>((ref) {
  final db = ref.read(databaseServiceProvider);
  return TasksNotifier(db);
});

final searchQueryProvider = StateProvider<String>((ref) => '');
final composerFocusRequestProvider = StateProvider<int>((ref) => 0);
final searchFocusRequestProvider = StateProvider<int>((ref) => 0);

final todayCountProvider = Provider<int>((ref) {
  final tasks = ref.watch(tasksProvider);
  final now = DateTime.now();
  return tasks.where((t) {
    if (t.isCompleted) return false;
    final due = t.dueDate;
    if (due == null) return false;
    return due.year == now.year &&
        due.month == now.month &&
        due.day == now.day;
  }).length;
});

final completedCountProvider = Provider<int>((ref) {
  return ref.watch(tasksProvider).where((t) => t.isCompleted).length;
});

final projectTaskCountsProvider = Provider<Map<String, int>>((ref) {
  final tasks = ref.watch(tasksProvider);
  final counts = <String, int>{};
  for (final t in tasks) {
    if (!t.isCompleted) {
      counts[t.projectId] = (counts[t.projectId] ?? 0) + 1;
    }
  }
  return counts;
});

final projectTaskCountProvider = Provider.family<int, String>((ref, projectId) {
  return ref.watch(projectTaskCountsProvider)[projectId] ?? 0;
});

final filteredTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(tasksProvider);
  final selection = ref.watch(sidebarSelectionProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();

  var filtered = switch (selection) {
    ViewSelection(:final view) => switch (view) {
        ViewType.inbox => tasks,
        ViewType.today => tasks.where((t) {
            final due = t.dueDate;
            if (due == null) return false;
            final now = DateTime.now();
            return due.year == now.year &&
                due.month == now.month &&
                due.day == now.day;
          }).toList(),
        ViewType.completed =>
          tasks.where((t) => t.isCompleted).toList(),
      },
    ProjectSelection(:final projectId) =>
      tasks.where((t) => t.projectId == projectId).toList(),
  };

  if (query.isNotEmpty) {
    filtered = filtered.where((t) {
      return t.title.toLowerCase().contains(query) ||
          (t.description?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  return filtered;
});

class TasksNotifier extends StateNotifier<List<Task>> {
  final DatabaseService _db;
  TasksNotifier(this._db) : super([]) {
    _load();
  }

  void _load() {
    _db.getTasks().then((tasks) {
      state = tasks;
    });
  }

  Future<void> addTask({
    required String title,
    String? description,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.none,
    String projectId = 'default',
  }) async {
    final task = await _db.insertTask(
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority.index,
      projectId: projectId,
    );
    state = [...state, task];
  }

  void toggleTask(String id) {
    state = state.map((t) {
      if (t.id != id) return t;
      final toggled = t.copyWith(isCompleted: !t.isCompleted);
      _db.updateTask(toggled);
      return toggled;
    }).toList();
  }

  void deleteTask(String id) {
    state = state.where((t) => t.id != id).toList();
    _db.deleteTask(id);
  }

  Future<void> clearCompleted() async {
    final completed = state.where((t) => t.isCompleted).toList();
    if (completed.isEmpty) return;
    state = state.where((t) => !t.isCompleted).toList();
    await _db.clearCompleted();
  }

  void updateTask(String id, Task updated) {
    state = state.map((t) {
      if (t.id != id) return t;
      _db.updateTask(updated);
      return updated;
    }).toList();
  }
}
