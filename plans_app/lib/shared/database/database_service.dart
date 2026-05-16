import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';
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
  bool isNewDatabase = false;

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
        version: 2,
        onCreate: (db, version) async {
          isNewDatabase = true;
          await db.execute('''
            CREATE TABLE tasks (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              description TEXT,
              due_date INTEGER,
              priority INTEGER NOT NULL DEFAULT 0,
              is_completed INTEGER NOT NULL DEFAULT 0,
              is_deleted INTEGER NOT NULL DEFAULT 0,
              project_id TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE projects (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              color_index INTEGER NOT NULL DEFAULT 0,
              is_deleted INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await db.execute('''
            CREATE TABLE changes (
              id TEXT PRIMARY KEY,
              entity_type TEXT NOT NULL,
              entity_id TEXT NOT NULL,
              operation TEXT NOT NULL,
              payload TEXT,
              timestamp INTEGER NOT NULL
            )
          ''');
          for (final proj in _defaultProjects) {
            await db.insert('projects', {
              'id': proj.id,
              'name': proj.name,
              'color_index': proj.colorIndex,
              'is_deleted': 0,
            });
          }
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute(
              'ALTER TABLE tasks ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0',
            );
            await db.execute(
              'ALTER TABLE projects ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0',
            );
            await db.execute('''
              CREATE TABLE changes (
                id TEXT PRIMARY KEY,
                entity_type TEXT NOT NULL,
                entity_id TEXT NOT NULL,
                operation TEXT NOT NULL,
                payload TEXT,
                timestamp INTEGER NOT NULL
              )
            ''');
          }
        },
      ),
    );
    return db;
  }

  // ── Tasks ──────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getTasks() async {
    final db = await database;
    return db.query('tasks', where: 'is_deleted = 0', orderBy: 'created_at ASC');
  }

  Future<void> insertTask(Task task) async {
    final db = await database;
    await db.insert('tasks', _taskToMap(task));
    await _logChange(db, 'task', task.id, 'create');
  }

  Future<void> updateTask(Task task) async {
    final db = await database;
    final map = _taskToMap(task);
    map.remove('id');
    await db.update('tasks', map, where: 'id = ?', whereArgs: [task.id]);
    await _logChange(db, 'task', task.id, 'update');
  }

  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.update(
      'tasks',
      {'is_deleted': 1, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
    await _logChange(db, 'task', id, 'delete');
  }

  // ── Projects ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getProjects() async {
    final db = await database;
    return db.query('projects', where: 'is_deleted = 0', orderBy: 'color_index ASC');
  }

  Future<void> insertProject(Project project) async {
    final db = await database;
    await db.insert('projects', {
      'id': project.id,
      'name': project.name,
      'color_index': project.colorIndex,
      'is_deleted': 0,
    });
    await _logChange(db, 'project', project.id, 'create');
  }

  Future<void> updateProject(Project project) async {
    final db = await database;
    await db.update(
      'projects',
      {'name': project.name, 'color_index': project.colorIndex},
      where: 'id = ?',
      whereArgs: [project.id],
    );
    await _logChange(db, 'project', project.id, 'update');
  }

  Future<void> deleteProject(String id) async {
    final db = await database;
    await db.update(
      'projects',
      {'is_deleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    await _logChange(db, 'project', id, 'delete');
  }

  // ── Internal ───────────────────────────────────────────────────────────────

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

  Future<void> _logChange(
    Database db,
    String entityType,
    String entityId,
    String operation,
  ) async {
    await db.insert('changes', {
      'id': const Uuid().v4(),
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': operation,
      'payload': null,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
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
