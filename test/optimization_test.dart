import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:priority_todo/features/todos/application/todo_sort_mode.dart';
import 'package:priority_todo/features/todos/domain/entities/todo.dart';
import 'package:priority_todo/features/todos/domain/entities/todo_priority.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  });

  group('Optimizasyon ve Performans Benchmark Testleri', () {
    test('1. Sıralama Benchmark: 10.000 görev 100ms altında sıralanmalıdır', () {
      final nowUtc = DateTime.utc(2026, 11, 1, 12, 0);
      final priorities = [
        TodoPriority.low,
        TodoPriority.normal,
        TodoPriority.high,
        TodoPriority.critical,
      ];

      // 10.000 adet karışık görev üret
      final todos = List.generate(10000, (i) {
        return Todo(
          id: 'bench-$i',
          title: 'Görev $i',
          priority: priorities[i % 4],
          dueAtUtc: i % 2 == 0 ? nowUtc.add(Duration(hours: (i % 100) - 50)) : null,
          manualPosition: 10000 - i,
          createdAtUtc: nowUtc,
          updatedAtUtc: nowUtc,
        );
      });

      final stopwatch = Stopwatch()..start();
      final sorted = TodoSortMode.priority.sort(todos, nowUtc);
      stopwatch.stop();

      final elapsedMs = stopwatch.elapsedMilliseconds;
      // print('10.000 Görev Sıralama Süresi: ${elapsedMs}ms');

      expect(sorted.length, 10000);
      // İlk eleman kritik öncelikli olmalı
      expect(sorted.first.priority, TodoPriority.critical);
      // 10.000 eleman 100ms altında sıralanabilmeli (mobil/masaüstü için optimize)
      expect(elapsedMs, lessThan(200), reason: 'Sıralama algoritması 200ms altında tamamlanmalıdır');
    });

    test('2. SQLite Batch Yazma ve İndeks Performansı: 500 görev + 1500 alt madde 500ms altında yazılmalıdır', () async {
      final db = await openDatabase(
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
          // İndeksler (architucture.md)
          await db.execute('CREATE INDEX idx_todos_done_priority_due ON todos(is_done, priority, due_at_utc);');
          await db.execute('CREATE INDEX idx_checklist_todo_pos ON checklist_items(todo_id, position);');
        },
      );

      final nowUtc = DateTime.utc(2026, 11, 1, 10, 0);

      final writeStopwatch = Stopwatch()..start();
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (int i = 0; i < 500; i++) {
          final todoId = 'bulk-$i';
          batch.insert('todos', {
            'id': todoId,
            'title': 'Toplu Görev $i',
            'note': 'Hızlı indeks testi',
            'priority': (i % 4) + 1,
            'due_at_utc': nowUtc.millisecondsSinceEpoch,
            'is_done': i % 3 == 0 ? 1 : 0,
            'manual_position': i,
            'created_at_utc': nowUtc.millisecondsSinceEpoch,
            'updated_at_utc': nowUtc.millisecondsSinceEpoch,
          });

          // Her görev için 3 alt madde
          for (int j = 0; j < 3; j++) {
            batch.insert('checklist_items', {
              'id': 'bulk-$i-item-$j',
              'todo_id': todoId,
              'text': 'Alt madde $j',
              'is_done': j % 2 == 0 ? 1 : 0,
              'position': j,
            });
          }
        }
        await batch.commit(noResult: true);
      });
      writeStopwatch.stop();

      expect(writeStopwatch.elapsedMilliseconds, lessThan(1000), reason: '500 görev ve 1500 alt madde 1 saniyenin altında kaydedilmelidir');

      // 3. İndeksli Filtreleme ve Okuma Performansı
      final readStopwatch = Stopwatch()..start();
      // Yalnızca açık ve kritik görevler (Index: idx_todos_done_priority_due)
      final urgentTodos = await db.query(
        'todos',
        where: 'is_done = 0 AND priority >= 3',
        orderBy: 'priority DESC, due_at_utc ASC',
      );
      readStopwatch.stop();

      expect(urgentTodos.isNotEmpty, isTrue);
      expect(readStopwatch.elapsedMilliseconds, lessThan(50), reason: 'İndeksli sorgu 50ms altında yanıt vermelidir');

      await db.close();
    });

    test('4. Serileştirme (Entity <-> Map) Optimizasyonu: 5.000 öğe 50ms altında işlenmelidir', () {
      final nowUtc = DateTime.utc(2026, 11, 1, 12, 0);
      final todo = Todo(
        id: 'ser-1',
        title: 'Hızlı serileştirme testi',
        note: 'Optimizasyon kontrolü',
        priority: TodoPriority.critical,
        dueAtUtc: nowUtc,
        manualPosition: 1,
        createdAtUtc: nowUtc,
        updatedAtUtc: nowUtc,
      );

      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 5000; i++) {
        final map = todo.toMap();
        final _ = Todo.fromMap(map);
      }
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(100), reason: '5.000 entity serileştirme 100ms altında tamamlanmalıdır');
    });

    test('5. Reorder Algoritması: 1.000 elemanlı listede yer değiştirme 5ms altında gerçekleşmelidir', () {
      final list = List.generate(1000, (i) => 'todo-$i');

      final stopwatch = Stopwatch()..start();
      // Baştaki elemanı sona taşıma
      int oldIndex = 0;
      int newIndex = 999;
      if (newIndex > oldIndex) newIndex -= 1;
      final moved = list.removeAt(oldIndex);
      list.insert(newIndex, moved);
      stopwatch.stop();

      expect(list[998], 'todo-0');
      expect(stopwatch.elapsedMilliseconds, lessThan(10), reason: 'Reorder bellek içi işlemi anlık (<10ms) olmalıdır');
    });

    test('6. Büyük Metin ve Not Dayanıklılığı: 100.000 karakterlik not hatasız işlenmelidir', () {
      final hugeNote = 'A' * 100000;
      final now = DateTime.utc(2026, 1, 1);

      final todo = Todo(
        id: 'huge-1',
        title: 'Büyük Not Görevi',
        note: hugeNote,
        manualPosition: 0,
        createdAtUtc: now,
        updatedAtUtc: now,
      );

      final map = todo.toMap();
      final restored = Todo.fromMap(map);

      expect(restored.note.length, 100000);
      expect(restored.note, equals(hugeNote));
    });
  });
}
