import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../features/tasks/models/task.dart';
import '../../features/projects/models/project.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  throw UnimplementedError('DatabaseService must be overridden in ProviderScope');
});

class DatabaseService {
  final String? _overridePath;
  DatabaseService({String? testPath}) : _overridePath = testPath;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final String path;
    if (_overridePath != null) {
      path = _overridePath;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      path = p.join(dir.path, 'plans.db');
    }
    final db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE tasks (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              description TEXT,
              due_date INTEGER,
              priority INTEGER NOT NULL DEFAULT 0,
              is_completed INTEGER NOT NULL DEFAULT 0,
              project_id TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE projects (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              color_index INTEGER NOT NULL DEFAULT 0
            )
          ''');
          for (final p in _defaultProjects) {
            await db.insert('projects', {
              'id': p.id,
              'name': p.name,
              'color_index': p.colorIndex,
            });
          }
        },
      ),
    );
    return db;
  }

  Future<List<Map<String, dynamic>>> getTasks() async {
    final db = await database;
    return db.query('tasks', orderBy: 'created_at ASC');
  }

  Future<void> insertTask(Task task) async {
    final db = await database;
    await db.insert('tasks', _taskToMap(task));
  }

  Future<void> updateTask(Task task) async {
    final db = await database;
    final map = _taskToMap(task);
    map.remove('id');
    await db.update('tasks', map, where: 'id = ?', whereArgs: [task.id]);
  }

  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getProjects() async {
    final db = await database;
    return db.query('projects', orderBy: 'color_index ASC');
  }

  Future<void> insertProject(Project project) async {
    final db = await database;
    await db.insert('projects', {
      'id': project.id,
      'name': project.name,
      'color_index': project.colorIndex,
    });
  }

  Map<String, dynamic> _taskToMap(Task task) {
    return {
      if (task.id.isNotEmpty) 'id': task.id,
      'title': task.title,
      'description': task.description,
      'due_date': task.dueDate?.millisecondsSinceEpoch,
      'priority': task.priority.index,
      'is_completed': task.isCompleted ? 1 : 0,
      'project_id': task.projectId,
      'created_at': task.createdAt.millisecondsSinceEpoch,
      'updated_at': task.updatedAt.millisecondsSinceEpoch,
    };
  }
}

const _defaultProjects = [
  _ProjectSeed(id: 'default', name: 'Inbox', colorIndex: 0),
  _ProjectSeed(id: 'work', name: 'Work', colorIndex: 1),
  _ProjectSeed(id: 'personal', name: 'Personal', colorIndex: 2),
  _ProjectSeed(id: 'ideas', name: 'Ideas', colorIndex: 3),
];

class _ProjectSeed {
  final String id;
  final String name;
  final int colorIndex;
  const _ProjectSeed({
    required this.id,
    required this.name,
    required this.colorIndex,
  });
}
