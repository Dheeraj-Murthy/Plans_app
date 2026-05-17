import 'package:plans_app/features/projects/models/project.dart';
import 'package:plans_app/features/tasks/models/task.dart';
import 'package:plans_app/shared/database/database_service.dart';
import 'package:uuid/uuid.dart';

class FakeDatabaseService extends DatabaseService {
  final List<Task> _tasks = [];
  final List<Project> _projects = [];

  void seedProject(Project p) => _projects.add(p);

  @override
  Future<List<Task>> getTasks() async => List.from(_tasks);

  @override
  Future<List<Project>> getProjects() async => List.from(_projects);

  @override
  Future<Task> insertTask({
    required String title,
    String? description,
    DateTime? dueDate,
    int priority = 0,
    String projectId = 'default',
  }) async {
    final task = Task(
      id: const Uuid().v4(),
      title: title,
      description: description,
      dueDate: dueDate,
      priority: TaskPriority.values[priority],
      projectId: projectId,
    );
    _tasks.add(task);
    return task;
  }

  @override
  Future<void> updateTask(Task task) async {
    final idx = _tasks.indexWhere((t) => t.id == task.id);
    if (idx >= 0) _tasks[idx] = task;
  }

  @override
  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
  }

  @override
  Future<void> clearCompleted() async {
    _tasks.removeWhere((t) => t.isCompleted);
  }

  @override
  Future<Project> insertProject({
    required String name,
    required int colorIndex,
  }) async {
    final project = Project(
      id: const Uuid().v4(),
      name: name,
      colorIndex: colorIndex,
    );
    _projects.add(project);
    return project;
  }

  @override
  Future<void> updateProject(Project project) async {
    final idx = _projects.indexWhere((p) => p.id == project.id);
    if (idx >= 0) _projects[idx] = project;
  }

  @override
  Future<void> deleteProject(String id) async {
    _projects.removeWhere((p) => p.id == id);
  }
}
