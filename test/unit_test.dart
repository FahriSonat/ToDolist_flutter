import 'package:flutter_test/flutter_test.dart';
import 'package:priority_todo/core/clock/clock.dart';
import 'package:priority_todo/features/settings/domain/settings_entity.dart';
import 'package:priority_todo/features/todos/application/todo_sort_mode.dart';
import 'package:priority_todo/features/todos/domain/entities/checklist_item.dart';
import 'package:priority_todo/features/todos/domain/entities/todo.dart';
import 'package:priority_todo/features/todos/domain/entities/todo_priority.dart';

class MockClock implements Clock {
  DateTime currentTime;
  MockClock(this.currentTime);

  @override
  DateTime now() => currentTime;

  @override
  DateTime nowUtc() => currentTime.toUtc();
}

void main() {
  group('1. Sıralama Kuralları Testleri (project.md)', () {
    final nowUtc = DateTime.utc(2026, 11, 1, 12, 0);

    test('Öncelik sıralaması: Kritik > Yüksek > Normal > Düşük', () {
      final todos = [
        Todo(
          id: '1',
          title: 'Düşük Görev',
          priority: TodoPriority.low,
          manualPosition: 0,
          createdAtUtc: nowUtc,
          updatedAtUtc: nowUtc,
        ),
        Todo(
          id: '2',
          title: 'Kritik Görev',
          priority: TodoPriority.critical,
          manualPosition: 1,
          createdAtUtc: nowUtc,
          updatedAtUtc: nowUtc,
        ),
        Todo(
          id: '3',
          title: 'Normal Görev',
          priority: TodoPriority.normal,
          manualPosition: 2,
          createdAtUtc: nowUtc,
          updatedAtUtc: nowUtc,
        ),
        Todo(
          id: '4',
          title: 'Yüksek Görev',
          priority: TodoPriority.high,
          manualPosition: 3,
          createdAtUtc: nowUtc,
          updatedAtUtc: nowUtc,
        ),
      ];

      final sorted = TodoSortMode.priority.sort(todos, nowUtc);
      expect(sorted[0].priority, TodoPriority.critical);
      expect(sorted[1].priority, TodoPriority.high);
      expect(sorted[2].priority, TodoPriority.normal);
      expect(sorted[3].priority, TodoPriority.low);
    });

    test('Öncelikler eşitse son tarihi yakın olan önce gelmelidir', () {
      final todos = [
        Todo(
          id: '1',
          title: 'Daha Geç Son Tarih',
          priority: TodoPriority.high,
          dueAtUtc: nowUtc.add(const Duration(hours: 5)),
          manualPosition: 0,
          createdAtUtc: nowUtc,
          updatedAtUtc: nowUtc,
        ),
        Todo(
          id: '2',
          title: 'Daha Yakın Son Tarih',
          priority: TodoPriority.high,
          dueAtUtc: nowUtc.add(const Duration(hours: 1)),
          manualPosition: 1,
          createdAtUtc: nowUtc,
          updatedAtUtc: nowUtc,
        ),
      ];

      final sorted = TodoSortMode.priority.sort(todos, nowUtc);
      expect(sorted[0].id, '2');
      expect(sorted[1].id, '1');
    });

    test('Özel sıra (manual) sıralaması manualPosition alanına göre sıralamalıdır', () {
      final todos = [
        Todo(
          id: '1',
          title: 'Görev 1',
          manualPosition: 2,
          createdAtUtc: nowUtc,
          updatedAtUtc: nowUtc,
        ),
        Todo(
          id: '2',
          title: 'Görev 2',
          manualPosition: 0,
          createdAtUtc: nowUtc,
          updatedAtUtc: nowUtc,
        ),
        Todo(
          id: '3',
          title: 'Görev 3',
          manualPosition: 1,
          createdAtUtc: nowUtc,
          updatedAtUtc: nowUtc,
        ),
      ];

      final sorted = TodoSortMode.manual.sort(todos, nowUtc);
      expect(sorted.map((t) => t.id).toList(), ['2', '3', '1']);
    });
  });

  group('2. Sessiz Saatler Testleri (project.md & architucture.md)', () {
    test('Sessiz saatler kapalıyken her saat bildirim gönderilebilir', () {
      const settings = SettingsEntity(
        quietHoursEnabled: false,
        quietHoursStartHour: 22,
        quietHoursEndHour: 8,
      );

      final midnight = DateTime(2026, 11, 1, 23, 30);
      expect(settings.isWithinQuietHours(midnight), isFalse);
    });

    test('Geceyi aşan aralık (22:00 - 08:00) doğru tespit edilmelidir', () {
      const settings = SettingsEntity(
        quietHoursEnabled: true,
        quietHoursStartHour: 22,
        quietHoursStartMinute: 0,
        quietHoursEndHour: 8,
        quietHoursEndMinute: 0,
      );

      expect(settings.isWithinQuietHours(DateTime(2026, 11, 1, 23, 0)), isTrue);
      expect(settings.isWithinQuietHours(DateTime(2026, 11, 1, 3, 30)), isTrue);
      expect(settings.isWithinQuietHours(DateTime(2026, 11, 1, 7, 59)), isTrue);
      expect(settings.isWithinQuietHours(DateTime(2026, 11, 1, 8, 1)), isFalse);
      expect(settings.isWithinQuietHours(DateTime(2026, 11, 1, 14, 0)), isFalse);
    });

    test('Gündüz aralığı (13:00 - 15:00) doğru tespit edilmelidir', () {
      const settings = SettingsEntity(
        quietHoursEnabled: true,
        quietHoursStartHour: 13,
        quietHoursStartMinute: 0,
        quietHoursEndHour: 15,
        quietHoursEndMinute: 0,
      );

      expect(settings.isWithinQuietHours(DateTime(2026, 11, 1, 14, 0)), isTrue);
      expect(settings.isWithinQuietHours(DateTime(2026, 11, 1, 12, 59)), isFalse);
      expect(settings.isWithinQuietHours(DateTime(2026, 11, 1, 15, 1)), isFalse);
    });
  });

  group('3. Görev Uç Durumları ve Süresi Geçti Testleri (project.md)', () {
    final nowUtc = DateTime.utc(2026, 11, 1, 15, 0);

    test('Son tarihi geçmiş ve tamamlanmamış görev isOverdue=true olmalıdır', () {
      final pastTodo = Todo(
        id: '1',
        title: 'Geçmiş Görev',
        dueAtUtc: nowUtc.subtract(const Duration(hours: 2)),
        isDone: false,
        manualPosition: 0,
        createdAtUtc: nowUtc,
        updatedAtUtc: nowUtc,
      );
      expect(pastTodo.isOverdue(nowUtc), isTrue);
    });

    test('Tamamlanan görevin süresi geçmiş olsa bile isOverdue=false olmalıdır', () {
      final doneTodo = Todo(
        id: '1',
        title: 'Tamamlanan Görev',
        dueAtUtc: nowUtc.subtract(const Duration(hours: 2)),
        isDone: true,
        manualPosition: 0,
        createdAtUtc: nowUtc,
        updatedAtUtc: nowUtc,
      );
      expect(doneTodo.isOverdue(nowUtc), isFalse);
    });

    test('Son tarihi olmayan görev isOverdue=false olmalıdır', () {
      final noDateTodo = Todo(
        id: '1',
        title: 'Tarihsiz Görev',
        dueAtUtc: null,
        isDone: false,
        manualPosition: 0,
        createdAtUtc: nowUtc,
        updatedAtUtc: nowUtc,
      );
      expect(noDateTodo.isOverdue(nowUtc), isFalse);
    });

    test('Kontrol listesi tamamlanma sayısı doğru hesaplanmalıdır', () {
      final todo = Todo(
        id: '1',
        title: 'Checklist Görevi',
        manualPosition: 0,
        createdAtUtc: nowUtc,
        updatedAtUtc: nowUtc,
        items: const [
          ChecklistItem(id: 'c1', todoId: '1', text: 'Madde 1', isDone: true, position: 0),
          ChecklistItem(id: 'c2', todoId: '1', text: 'Madde 2', isDone: false, position: 1),
          ChecklistItem(id: 'c3', todoId: '1', text: 'Madde 3', isDone: true, position: 2),
        ],
      );

      expect(todo.totalItemsCount, 3);
      expect(todo.completedItemsCount, 2);
      expect(todo.hasChecklist, isTrue);
    });
  });
}
