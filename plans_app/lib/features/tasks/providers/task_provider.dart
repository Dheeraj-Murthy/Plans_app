import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
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

final projectTaskCountProvider = Provider.family<int, String>((ref, projectId) {
  return ref
      .watch(tasksProvider)
      .where((t) => t.projectId == projectId && !t.isCompleted)
      .length;
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
    _db.getTasks().then((rows) {
      if (rows.isEmpty && _db.isNewDatabase) {
        _seedSampleData();
      } else {
        state = rows.map((r) => Task.fromMap(r)).toList();
      }
    });
  }

  Future<void> _seedSampleData() async {
    final uuid = const Uuid();
    final tasks = [
      Task(
        id: uuid.v4(),
        title: 'Set up Flutter project structure',
        description: 'Create features/, shared/, routing/, theme/ folders',
        priority: TaskPriority.high,
        projectId: 'work',
      ),
      Task(
        id: uuid.v4(),
        title: 'Build task list UI',
        priority: TaskPriority.medium,
        projectId: 'work',
      ),
      Task(
        id: uuid.v4(),
        title: 'Buy groceries',
        dueDate: DateTime.now().add(const Duration(days: 1)),
        priority: TaskPriority.medium,
        projectId: 'personal',
      ),
      Task(
        id: uuid.v4(),
        title: 'Read about Riverpod',
        projectId: 'personal',
      ),
      Task(
        id: uuid.v4(),
        title: 'Write sync engine design',
        description: 'Think through conflict resolution strategy',
        priority: TaskPriority.low,
        projectId: 'ideas',
      ),
    ];
    state = tasks;
    for (final t in tasks) {
      await _db.insertTask(t);
    }
  }

  void addTask({
    required String title,
    String? description,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.none,
    String projectId = 'default',
  }) {
    final task = Task(
      id: const Uuid().v4(),
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
      projectId: projectId,
    );
    state = [...state, task];
    _db.insertTask(task);
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
    for (final t in completed) {
      await _db.deleteTask(t.id);
    }
  }

  void updateTask(String id, Task updated) {
    state = state.map((t) {
      if (t.id != id) return t;
      _db.updateTask(updated);
      return updated;
    }).toList();
  }
}
