import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../../../core/clock/clock.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/checklist_item.dart';
import '../../domain/entities/todo.dart';
import '../../domain/repositories/todo_repository.dart';
import '../database/app_database.dart';

/// SQLite tabanlı Todo Repository implementasyonu (architucture.md & Skill.md)
class SqliteTodoRepository implements TodoRepository {
  final Clock clock;
  final StreamController<void> _updateController = StreamController<void>.broadcast();

  SqliteTodoRepository({this.clock = const SystemClock()});

  Future<Database> get _db => AppDatabase.getInstance();

  void _notifyUpdate() {
    if (!_updateController.isClosed) {
      _updateController.add(null);
    }
  }

  @override
  Stream<List<Todo>> watchTodos({required bool isDone}) async* {
    yield await getTodos(isDone: isDone);
    await for (final _ in _updateController.stream) {
      yield await getTodos(isDone: isDone);
    }
  }

  @override
  Future<List<Todo>> getTodos({required bool isDone}) async {
    try {
      final db = await _db;
      final maps = await db.query(
        'todos',
        where: 'is_done = ?',
        whereArgs: [isDone ? 1 : 0],
        orderBy: 'manual_position ASC, created_at_utc DESC',
      );

      final todos = <Todo>[];
      for (final map in maps) {
        final id = map['id'] as String;
        final itemMaps = await db.query(
          'checklist_items',
          where: 'todo_id = ?',
          whereArgs: [id],
          orderBy: 'position ASC',
        );
        final items = itemMaps.map((m) => ChecklistItem.fromMap(m)).toList();
        todos.add(Todo.fromMap(map, items));
      }
      return todos;
    } catch (e) {
      throw AppDatabaseException('Görevler listelenirken hata oluştu', e);
    }
  }

  @override
  Future<List<Todo>> getUrgentPendingTodos() async {
    try {
      final db = await _db;
      // Öncelik 3 (Yüksek) ve 4 (Kritik), tamamlanmamış
      final maps = await db.query(
        'todos',
        where: 'is_done = 0 AND priority >= 3',
        orderBy: 'priority DESC, due_at_utc ASC',
      );

      final todos = <Todo>[];
      for (final map in maps) {
        final id = map['id'] as String;
        final itemMaps = await db.query(
          'checklist_items',
          where: 'todo_id = ?',
          whereArgs: [id],
          orderBy: 'position ASC',
        );
        final items = itemMaps.map((m) => ChecklistItem.fromMap(m)).toList();
        todos.add(Todo.fromMap(map, items));
      }
      return todos;
    } catch (e) {
      throw AppDatabaseException('Acil görevler getirilemedi', e);
    }
  }

  @override
  Future<Todo?> getTodoById(String id) async {
    try {
      final db = await _db;
      final maps = await db.query(
        'todos',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) return null;

      final itemMaps = await db.query(
        'checklist_items',
        where: 'todo_id = ?',
        whereArgs: [id],
        orderBy: 'position ASC',
      );
      final items = itemMaps.map((m) => ChecklistItem.fromMap(m)).toList();
      return Todo.fromMap(maps.first, items);
    } catch (e) {
      throw AppDatabaseException('Görev detayı getirilemedi', e);
    }
  }

  @override
  Future<void> saveTodo(Todo todo) async {
    final title = todo.title.trim();
    if (title.isEmpty || title.length > 160) {
      throw const ValidationException('Başlık 1 ile 160 karakter arasında olmalıdır');
    }

    try {
      final db = await _db;
      await db.transaction((txn) async {
        await txn.insert(
          'todos',
          todo.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        for (final item in todo.items) {
          final itemText = item.text.trim();
          if (itemText.isNotEmpty && itemText.length <= 500) {
            await txn.insert(
              'checklist_items',
              item.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      });
      _notifyUpdate();
    } catch (e) {
      throw AppDatabaseException('Görev kaydedilemedi', e);
    }
  }

  @override
  Future<void> updateTodo(Todo todo) async {
    final title = todo.title.trim();
    if (title.isEmpty || title.length > 160) {
      throw const ValidationException('Başlık 1 ile 160 karakter arasında olmalıdır');
    }

    try {
      final db = await _db;
      final nowUtc = clock.nowUtc();
      final updated = todo.copyWith(updatedAtUtc: nowUtc);

      await db.transaction((txn) async {
        await txn.update(
          'todos',
          updated.toMap(),
          where: 'id = ?',
          whereArgs: [updated.id],
        );

        // Checklist maddelerini senkronize et
        await txn.delete(
          'checklist_items',
          where: 'todo_id = ?',
          whereArgs: [updated.id],
        );

        for (final item in updated.items) {
          final itemText = item.text.trim();
          if (itemText.isNotEmpty && itemText.length <= 500) {
            await txn.insert(
              'checklist_items',
              item.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      });
      _notifyUpdate();
    } catch (e) {
      throw AppDatabaseException('Görev güncellenemedi', e);
    }
  }

  @override
  Future<void> deleteTodo(String id) async {
    try {
      final db = await _db;
      await db.transaction((txn) async {
        await txn.delete('checklist_items', where: 'todo_id = ?', whereArgs: [id]);
        await txn.delete('todos', where: 'id = ?', whereArgs: [id]);
      });
      _notifyUpdate();
    } catch (e) {
      throw AppDatabaseException('Görev silinemedi', e);
    }
  }

  @override
  Future<void> toggleTodoDone(String id, bool isDone) async {
    try {
      final db = await _db;
      final nowUtc = clock.nowUtc();
      await db.update(
        'todos',
        {
          'is_done': isDone ? 1 : 0,
          'updated_at_utc': nowUtc.millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      _notifyUpdate();
    } catch (e) {
      throw AppDatabaseException('Görev durumu güncellenemedi', e);
    }
  }

  @override
  Future<void> toggleChecklistItem({
    required String todoId,
    required String itemId,
    required bool isDone,
  }) async {
    try {
      final db = await _db;
      final nowUtc = clock.nowUtc();
      await db.transaction((txn) async {
        await txn.update(
          'checklist_items',
          {'is_done': isDone ? 1 : 0},
          where: 'id = ? AND todo_id = ?',
          whereArgs: [itemId, todoId],
        );

        await txn.update(
          'todos',
          {'updated_at_utc': nowUtc.millisecondsSinceEpoch},
          where: 'id = ?',
          whereArgs: [todoId],
        );
      });
      _notifyUpdate();
    } catch (e) {
      throw AppDatabaseException('Kontrol listesi güncellenemedi', e);
    }
  }

  @override
  Future<void> addChecklistItem(ChecklistItem item) async {
    final text = item.text.trim();
    if (text.isEmpty || text.length > 500) {
      throw const ValidationException('Madde 1 ile 500 karakter arasında olmalıdır');
    }

    try {
      final db = await _db;
      final nowUtc = clock.nowUtc();
      await db.transaction((txn) async {
        await txn.insert(
          'checklist_items',
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await txn.update(
          'todos',
          {'updated_at_utc': nowUtc.millisecondsSinceEpoch},
          where: 'id = ?',
          whereArgs: [item.todoId],
        );
      });
      _notifyUpdate();
    } catch (e) {
      throw AppDatabaseException('Madde eklenemedi', e);
    }
  }

  @override
  Future<void> deleteChecklistItem({
    required String todoId,
    required String itemId,
  }) async {
    try {
      final db = await _db;
      final nowUtc = clock.nowUtc();
      await db.transaction((txn) async {
        await txn.delete(
          'checklist_items',
          where: 'id = ? AND todo_id = ?',
          whereArgs: [itemId, todoId],
        );
        await txn.update(
          'todos',
          {'updated_at_utc': nowUtc.millisecondsSinceEpoch},
          where: 'id = ?',
          whereArgs: [todoId],
        );
      });
      _notifyUpdate();
    } catch (e) {
      throw AppDatabaseException('Madde silinemedi', e);
    }
  }

  @override
  Future<void> reorderTodos(List<String> orderedTodoIds) async {
    try {
      final db = await _db;
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (int i = 0; i < orderedTodoIds.length; i++) {
          batch.update(
            'todos',
            {'manual_position': i},
            where: 'id = ?',
            whereArgs: [orderedTodoIds[i]],
          );
        }
        await batch.commit(noResult: true);
      });
      _notifyUpdate();
    } catch (e) {
      throw AppDatabaseException('Sıralama güncellenemedi', e);
    }
  }

  @override
  Future<void> reorderChecklistItems(String todoId, List<String> orderedItemIds) async {
    try {
      final db = await _db;
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (int i = 0; i < orderedItemIds.length; i++) {
          batch.update(
            'checklist_items',
            {'position': i},
            where: 'id = ? AND todo_id = ?',
            whereArgs: [orderedItemIds[i], todoId],
          );
        }
        await batch.commit(noResult: true);
      });
      _notifyUpdate();
    } catch (e) {
      throw AppDatabaseException('Alt maddelerin sırası güncellenemedi', e);
    }
  }

  @override
  Future<void> updateLastRemindedAt(String id, DateTime remindedAtUtc) async {
    try {
      final db = await _db;
      await db.update(
        'todos',
        {'last_reminded_at_utc': remindedAtUtc.millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [id],
      );
      _notifyUpdate();
    } catch (e) {
      throw AppDatabaseException('Son hatırlatma zamanı güncellenemedi', e);
    }
  }

  @override
  Future<void> clearAllData() async {
    try {
      final db = await _db;
      await db.transaction((txn) async {
        await txn.delete('checklist_items');
        await txn.delete('todos');
      });
      _notifyUpdate();
    } catch (e) {
      throw AppDatabaseException('Veriler temizlenemedi', e);
    }
  }
}
