import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../../projects/providers/project_provider.dart';
import '../../../shared/database/database_service.dart';
import '../../../shared/notifications/notification_service.dart';
import '../../../shared/widgets/widget_bridge.dart';

sealed class UndoAction {}

class TaskDeleted extends UndoAction {
  final Task task;
  TaskDeleted(this.task);
}

class TaskToggled extends UndoAction {
  final String id;
  final bool wasCompleted;
  TaskToggled(this.id, this.wasCompleted);
}

final undoStackProvider =
    NotifierProvider<UndoStackNotifier, List<UndoAction>>(
  UndoStackNotifier.new,
);

class _LastUndoActionNotifier extends Notifier<UndoAction?> {
  @override
  UndoAction? build() => null;
  void set(UndoAction? action) => state = action;
}

final lastUndoActionProvider =
    NotifierProvider<_LastUndoActionNotifier, UndoAction?>(
  _LastUndoActionNotifier.new,
);

class UndoStackNotifier extends Notifier<List<UndoAction>> {
  @override
  List<UndoAction> build() => [];

  void push(UndoAction action) => state = [...state, action];

  UndoAction? pop() {
    if (state.isEmpty) return null;
    final action = state.last;
    state = state.sublist(0, state.length - 1);
    return action;
  }
}

class _SetNotifier extends Notifier<Set<String>> {
  final Map<String, Timer> _timers = {};

  @override
  Set<String> build() {
    ref.onDispose(() {
      for (final t in _timers.values) { t.cancel(); }
      _timers.clear();
    });
    return {};
  }

  void add(String id, int delayMs) {
    _timers[id]?.cancel();
    state = {...state, id};
    _timers[id] = Timer(Duration(milliseconds: delayMs), () {
      state = Set<String>.from(state)..remove(id);
      _timers.remove(id);
    });
  }

  void remove(String id) {
    _timers[id]?.cancel();
    _timers.remove(id);
    if (state.contains(id)) {
      state = Set<String>.from(state)..remove(id);
    }
  }
}

final completingTaskIdsProvider =
    NotifierProvider<_SetNotifier, Set<String>>(_SetNotifier.new);

final uncompletingTaskIdsProvider =
    NotifierProvider<_SetNotifier, Set<String>>(_SetNotifier.new);

final tasksProvider =
    NotifierProvider<TasksNotifier, List<Task>>(TasksNotifier.new);

class _StringNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}

final searchQueryProvider =
    NotifierProvider<_StringNotifier, String>(_StringNotifier.new);

class _CounterNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void request() => state++;
}

final composerFocusRequestProvider =
    NotifierProvider<_CounterNotifier, int>(_CounterNotifier.new);
final searchFocusRequestProvider =
    NotifierProvider<_CounterNotifier, int>(_CounterNotifier.new);

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
  final SidebarSelection selection = ref.watch(sidebarSelectionProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  final completingIds = ref.watch(completingTaskIdsProvider);
  final uncompletingIds = ref.watch(uncompletingTaskIdsProvider);

  var filtered = switch (selection) {
    ViewSelection(:final view) => switch (view) {
        ViewType.inbox => tasks.where((t) {
          if (!t.isCompleted) return true;
          if (completingIds.contains(t.id)) return true;
          return false;
        }).toList(),
        ViewType.today => tasks.where((t) {
            final due = t.dueDate;
            if (due == null) return false;
            final now = DateTime.now();
            return due.year == now.year &&
                due.month == now.month &&
                due.day == now.day;
          }).toList(),
        ViewType.completed => tasks.where((t) {
          if (t.isCompleted) return true;
          if (uncompletingIds.contains(t.id)) return true;
          return false;
        }).toList(),
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

class TasksNotifier extends Notifier<List<Task>> {
  late final DatabaseService _db;
  Timer? _widgetUpdateTimer;

  @override
  List<Task> build() {
    _db = ref.read(databaseServiceProvider);
    ref.onDispose(() => _widgetUpdateTimer?.cancel());
    _load();
    return [];
  }

  void _debouncedWidgetUpdate() {
    _widgetUpdateTimer?.cancel();
    _widgetUpdateTimer = Timer(const Duration(seconds: 2), () {
      WidgetBridge.notifyUpdate(allTasks: state);
    });
  }

  void _load() {
    _db.getTasks().then((tasks) {
      state = tasks;
      NotificationService.rescheduleAll(tasks);
      WidgetBridge.notifyUpdate(allTasks: state, allProjects: ref.read(projectsProvider));
    }).catchError((e, st) {
      debugPrint('TasksNotifier._load failed: $e\n$st');
    });
  }

  Future<void> addTask({
    required String title,
    String? description,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.none,
    String projectId = 'default',
    int? reminderMinutes,
  }) async {
    final task = await _db.insertTask(
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority.index,
      projectId: projectId,
      reminderMinutes: reminderMinutes,
    );
    state = [...state, task];
    NotificationService.scheduleForTask(task);
    _debouncedWidgetUpdate();
  }

  bool toggleTask(String id) {
    final index = state.indexWhere((t) => t.id == id);
    if (index == -1) return false;

    final task = state[index];
    final wasCompleted = task.isCompleted;
    final toggled = task.copyWith(isCompleted: !wasCompleted);

    final newState = List<Task>.of(state);
    newState[index] = toggled;
    state = newState;

    _db.updateTask(toggled);
    if (toggled.isCompleted) {
      NotificationService.cancelForTask(id);
    } else {
      NotificationService.scheduleForTask(toggled);
    }

    if (!wasCompleted) {
      ref.read(uncompletingTaskIdsProvider.notifier).remove(id);
      final selection = ref.read(sidebarSelectionProvider);
      final isInbox = selection is ViewSelection && selection.view == ViewType.inbox;
      if (isInbox) {
        ref.read(completingTaskIdsProvider.notifier).add(id, 5300);
      }
    } else {
      ref.read(completingTaskIdsProvider.notifier).remove(id);
      ref.read(uncompletingTaskIdsProvider.notifier).add(id, 300);
    }

    _debouncedWidgetUpdate();
    return wasCompleted;
  }

  Task? deleteTask(String id) {
    final task = state.where((t) => t.id == id).firstOrNull;
    state = state.where((t) => t.id != id).toList();
    _db.deleteTask(id);
    NotificationService.cancelForTask(id);
    _debouncedWidgetUpdate();
    return task;
  }

  Future<void> restoreTask(Task task) async {
    await _db.restoreTask(task.id);
    state = [...state, task];
    NotificationService.scheduleForTask(task);
    _debouncedWidgetUpdate();
  }

  void updateTask(String id, Task updated) {
    final idx = state.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final newState = List<Task>.of(state);
    newState[idx] = updated;
    state = newState;
    _db.updateTask(updated);
    NotificationService.scheduleForTask(updated);
    _debouncedWidgetUpdate();
  }

  void reorderTask(int oldIndex, int newIndex) {
    final tasks = List<Task>.from(state);
    final moved = tasks.removeAt(oldIndex);
    tasks.insert(newIndex, moved);
    state = tasks;
    _db.reorderTasks(tasks.map((t) => t.id).toList());
    _debouncedWidgetUpdate();
  }
}
