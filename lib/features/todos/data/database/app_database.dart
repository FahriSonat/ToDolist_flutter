import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// SQLite Veritabanı Yöneticisi (architucture.md)
class AppDatabase {
  static Database? _database;
  static const String _dbName = 'priority_todo.db';
  static const int _dbVersion = 1;

  static Future<Database> getInstance() async {
    if (_database != null) return _database!;

    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await _resolveDatabasePath();
    _database = await openDatabase(
      dbPath,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: (db, version) async {
        await _createTables(db);
      },
    );

    return _database!;
  }

  static Future<String> _resolveDatabasePath() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final appDocDir = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(appDocDir.path, 'PriorityTodo'));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return p.join(dir.path, _dbName);
    } else {
      final databasesPath = await getDatabasesPath();
      return p.join(databasesPath, _dbName);
    }
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE todos (
        id TEXT PRIMARY KEY NOT NULL,
        title TEXT NOT NULL CHECK(length(trim(title)) BETWEEN 1 AND 160),
        note TEXT NOT NULL DEFAULT '',
        priority INTEGER NOT NULL CHECK(priority BETWEEN 1 AND 4),
        due_at_utc INTEGER,
        is_done INTEGER NOT NULL DEFAULT 0,
        manual_position INTEGER NOT NULL,
        last_reminded_at_utc INTEGER,
        created_at_utc INTEGER NOT NULL,
        updated_at_utc INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE checklist_items (
        id TEXT PRIMARY KEY NOT NULL,
        todo_id TEXT NOT NULL REFERENCES todos(id) ON DELETE CASCADE,
        text TEXT NOT NULL CHECK(length(trim(text)) BETWEEN 1 AND 500),
        is_done INTEGER NOT NULL DEFAULT 0,
        position INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE INDEX idx_todos_done_priority_due ON todos(is_done, priority, due_at_utc);
    ''');

    await db.execute('''
      CREATE INDEX idx_checklist_todo_pos ON checklist_items(todo_id, position);
    ''');
  }

  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
