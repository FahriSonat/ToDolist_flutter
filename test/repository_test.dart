import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:priority_todo/core/clock/clock.dart';
import 'package:priority_todo/features/todos/domain/entities/checklist_item.dart';
import 'package:priority_todo/features/todos/domain/entities/todo.dart';
import 'package:priority_todo/features/todos/domain/entities/todo_priority.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class TestClock implements Clock {
  DateTime time;
  TestClock(this.time);

  @override
  DateTime now() => time;

  @override
  DateTime nowUtc() => time.toUtc();
}

void main() {
  setUpAll(() {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  });

  group('Repository ve SQLite Cascade Delete Testleri (architucture.md)', () {
    late Database testDb;
    late TestClock clock;

    setUp(() async {
      clock = TestClock(DateTime.utc(2026, 11, 1, 10, 0));
      testDb = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON;');
        },
        onCreate: (db, version) async {
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
        },
      );

    });

    tearDown(() async {
      await testDb.close();
    });

    test('Görev eklendiğinde alt maddeleriyle birlikte kaydedilmelidir', () async {
      final now = clock.nowUtc();
      final todo = Todo(
        id: 'todo-1',
        title: 'Veritabanı Testi',
        note: 'Uzun açıklama metni',
        priority: TodoPriority.critical,
        manualPosition: 0,
        createdAtUtc: now,
        updatedAtUtc: now,
        items: const [
          ChecklistItem(id: 'item-1', todoId: 'todo-1', text: 'Alt madde 1', position: 0),
          ChecklistItem(id: 'item-2', todoId: 'todo-1', text: 'Alt madde 2', position: 1),
        ],
      );

      // Veritabanına doğrudan transaction ile ekle
      await testDb.transaction((txn) async {
        await txn.insert('todos', todo.toMap());
        for (final item in todo.items) {
          await txn.insert('checklist_items', item.toMap());
        }
      });

      final todosFromDb = await testDb.query('todos', where: 'id = ?', whereArgs: ['todo-1']);
      expect(todosFromDb.length, 1);
      expect(todosFromDb.first['title'], 'Veritabanı Testi');

      final itemsFromDb = await testDb.query('checklist_items', where: 'todo_id = ?', whereArgs: ['todo-1']);
      expect(itemsFromDb.length, 2);
    });

    test('Cascade Delete: Görev silindiğinde tüm alt maddeleri otomatik silinmelidir', () async {
      final now = clock.nowUtc();
      final todo = Todo(
        id: 'todo-cascade',
        title: 'Silinecek Görev',
        priority: TodoPriority.normal,
        manualPosition: 0,
        createdAtUtc: now,
        updatedAtUtc: now,
        items: const [
          ChecklistItem(id: 'c1', todoId: 'todo-cascade', text: 'Madde A', position: 0),
          ChecklistItem(id: 'c2', todoId: 'todo-cascade', text: 'Madde B', position: 1),
          ChecklistItem(id: 'c3', todoId: 'todo-cascade', text: 'Madde C', position: 2),
        ],
      );

      await testDb.transaction((txn) async {
        await txn.insert('todos', todo.toMap());
        for (final item in todo.items) {
          await txn.insert('checklist_items', item.toMap());
        }
      });

      // Silmeden önce 3 alt madde olduğunu doğrula
      final beforeDelete = await testDb.query('checklist_items', where: 'todo_id = ?', whereArgs: ['todo-cascade']);
      expect(beforeDelete.length, 3);

      // Ana görevi sil
      await testDb.delete('todos', where: 'id = ?', whereArgs: ['todo-cascade']);

      // ON DELETE CASCADE sayesinde alt maddeler de silinmiş olmalıdır
      final afterDelete = await testDb.query('checklist_items', where: 'todo_id = ?', whereArgs: ['todo-cascade']);
      expect(afterDelete, isEmpty);
    });

    test('Acil görev sorgusu sadece is_done=0 ve priority>=3 (Yüksek/Kritik) getirmelidir', () async {
      final now = clock.nowUtc();
      final todos = [
        Todo(id: '1', title: 'Düşük Açık', priority: TodoPriority.low, isDone: false, manualPosition: 0, createdAtUtc: now, updatedAtUtc: now),
        Todo(id: '2', title: 'Normal Açık', priority: TodoPriority.normal, isDone: false, manualPosition: 1, createdAtUtc: now, updatedAtUtc: now),
        Todo(id: '3', title: 'Yüksek Açık', priority: TodoPriority.high, isDone: false, manualPosition: 2, createdAtUtc: now, updatedAtUtc: now),
        Todo(id: '4', title: 'Kritik Açık', priority: TodoPriority.critical, isDone: false, manualPosition: 3, createdAtUtc: now, updatedAtUtc: now),
        Todo(id: '5', title: 'Kritik Tamamlanmış', priority: TodoPriority.critical, isDone: true, manualPosition: 4, createdAtUtc: now, updatedAtUtc: now),
      ];

      for (final t in todos) {
        await testDb.insert('todos', t.toMap());
      }

      final urgentMaps = await testDb.query(
        'todos',
        where: 'is_done = 0 AND priority >= 3',
        orderBy: 'priority DESC',
      );

      expect(urgentMaps.length, 2);
      final ids = urgentMaps.map((m) => m['id']).toList();
      expect(ids, containsAll(['3', '4']));
      expect(ids, isNot(contains('5'))); // Tamamlanmış dahil edilmez
    });

    test('Reorder işlemi: manual_position batch olarak güncellenmelidir', () async {
      final now = clock.nowUtc();
      final todos = [
        Todo(id: 'A', title: 'A', manualPosition: 0, createdAtUtc: now, updatedAtUtc: now),
        Todo(id: 'B', title: 'B', manualPosition: 1, createdAtUtc: now, updatedAtUtc: now),
        Todo(id: 'C', title: 'C', manualPosition: 2, createdAtUtc: now, updatedAtUtc: now),
      ];

      for (final t in todos) {
        await testDb.insert('todos', t.toMap());
      }

      // Sırayı C, A, B yap
      final newOrder = ['C', 'A', 'B'];
      await testDb.transaction((txn) async {
        final batch = txn.batch();
        for (int i = 0; i < newOrder.length; i++) {
          batch.update('todos', {'manual_position': i}, where: 'id = ?', whereArgs: [newOrder[i]]);
        }
        await batch.commit(noResult: true);
      });

      final query = await testDb.query('todos', orderBy: 'manual_position ASC');
      expect(query.map((m) => m['id']).toList(), ['C', 'A', 'B']);
    });
  });
}
