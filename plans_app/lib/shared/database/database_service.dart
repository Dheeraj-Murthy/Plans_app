import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plans_app/src/rust/api/tasks.dart' as rust_tasks;
import 'package:plans_app/src/rust/api/projects.dart' as rust_projects;
import 'package:plans_app/src/rust/models.dart' as rust_models;
import 'package:plans_app/features/tasks/models/task.dart';
import 'package:plans_app/features/projects/models/project.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  throw UnimplementedError('DatabaseService must be overridden in ProviderScope');
});

class DatabaseService {
  Future<List<Task>> getTasks() async {
    try {
      final raw = await rust_tasks.getAllTasks();
      return raw.map(_rustTaskToDomain).toList();
    } catch (e) {
      debugPrint('DatabaseService.getTasks failed: $e');
      return [];
    }
  }

  Future<Task> insertTask({
    required String title,
    String? description,
    DateTime? dueDate,
    int priority = 0,
    String projectId = 'default',
    int? reminderMinutes,
  }) async {
    try {
      final raw = await rust_tasks.createTask(
        title: title,
        description: description,
        dueDate: dueDate?.millisecondsSinceEpoch,
        priority: priority,
        projectId: projectId,
        reminderMinutes: reminderMinutes,
      );
      return _rustTaskToDomain(raw);
    } catch (e) {
      debugPrint('DatabaseService.insertTask failed: $e');
      rethrow;
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      final json = jsonEncode({
        'id': task.id,
        'title': task.title,
        'description': task.description,
        'due_date': task.dueDate?.millisecondsSinceEpoch,
        'priority': task.priority.index,
        'is_completed': task.isCompleted,
        'project_id': task.projectId,
        'created_at': task.createdAt.millisecondsSinceEpoch,
        'updated_at': task.updatedAt.millisecondsSinceEpoch,
        'sort_order': task.sortOrder,
        'reminder_minutes': task.reminderMinutes,
      });
      await rust_tasks.updateTask(taskJson: json);
    } catch (e) {
      debugPrint('DatabaseService.updateTask failed: $e');
      rethrow;
    }
  }

  Future<void> reorderTasks(List<String> orderedIds) async {
    try {
      await rust_tasks.reorderTasks(taskIds: orderedIds);
    } catch (e) {
      debugPrint('DatabaseService.reorderTasks failed: $e');
      rethrow;
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await rust_tasks.deleteTask(id: id);
    } catch (e) {
      debugPrint('DatabaseService.deleteTask failed: $e');
      rethrow;
    }
  }

  Future<void> restoreTask(String id) async {
    try {
      await rust_tasks.restoreTask(id: id);
    } catch (e) {
      debugPrint('DatabaseService.restoreTask failed: $e');
      rethrow;
    }
  }

  Future<void> clearCompleted() async {
    try {
      await rust_tasks.clearCompleted();
    } catch (e) {
      debugPrint('DatabaseService.clearCompleted failed: $e');
      rethrow;
    }
  }

  Future<List<Project>> getProjects() async {
    try {
      final raw = await rust_projects.getAllProjects();
      return raw.map(_rustProjectToDomain).toList();
    } catch (e) {
      debugPrint('DatabaseService.getProjects failed: $e');
      return [];
    }
  }

  Future<Project> insertProject({
    required String name,
    required int colorIndex,
  }) async {
    try {
      final raw = await rust_projects.createProject(
        name: name,
        colorIndex: colorIndex,
      );
      return _rustProjectToDomain(raw);
    } catch (e) {
      debugPrint('DatabaseService.insertProject failed: $e');
      rethrow;
    }
  }

  Future<void> updateProject(Project project) async {
    try {
      await rust_projects.updateProject(
        id: project.id,
        name: project.name,
        colorIndex: project.colorIndex,
      );
    } catch (e) {
      debugPrint('DatabaseService.updateProject failed: $e');
      rethrow;
    }
  }

  Future<void> deleteProject(String id) async {
    try {
      await rust_projects.deleteProject(id: id);
    } catch (e) {
      debugPrint('DatabaseService.deleteProject failed: $e');
      rethrow;
    }
  }

  Task _rustTaskToDomain(rust_models.Task t) {
    return Task(
      id: t.id,
      title: t.title,
      description: t.description,
      dueDate: t.dueDate != null
          ? DateTime.fromMillisecondsSinceEpoch(t.dueDate!)
          : null,
      priority: TaskPriority.values[t.priority.toInt()],
      isCompleted: t.isCompleted,
      projectId: t.projectId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(t.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(t.updatedAt),
      sortOrder: t.sortOrder.toInt(),
      reminderMinutes: t.reminderMinutes?.toInt(),
    );
  }

  Project _rustProjectToDomain(rust_models.Project p) {
    return Project(
      id: p.id,
      name: p.name,
      colorIndex: p.colorIndex.toInt(),
    );
  }
}
