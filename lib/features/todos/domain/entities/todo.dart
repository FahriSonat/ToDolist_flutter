import 'checklist_item.dart';
import 'todo_priority.dart';

/// Görev varlığı (project.md & architucture.md)
class Todo {
  final String id;
  final String title;
  final String note;
  final TodoPriority priority;
  final DateTime? dueAtUtc;
  final bool isDone;
  final int manualPosition;
  final DateTime? lastRemindedAtUtc;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  final List<ChecklistItem> items;

  const Todo({
    required this.id,
    required this.title,
    this.note = '',
    this.priority = TodoPriority.normal,
    this.dueAtUtc,
    this.isDone = false,
    required this.manualPosition,
    this.lastRemindedAtUtc,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    this.items = const [],
  });

  /// Son tarihin geçip geçmediğini UTC olarak kontrol eder
  bool isOverdue(DateTime nowUtc) {
    if (isDone || dueAtUtc == null) return false;
    return dueAtUtc!.isBefore(nowUtc);
  }

  int get totalItemsCount => items.length;
  int get completedItemsCount => items.where((i) => i.isDone).length;
  bool get hasChecklist => items.isNotEmpty;

  Todo copyWith({
    String? id,
    String? title,
    String? note,
    TodoPriority? priority,
    DateTime? dueAtUtc,
    bool clearDueAt = false,
    bool? isDone,
    int? manualPosition,
    DateTime? lastRemindedAtUtc,
    DateTime? createdAtUtc,
    DateTime? updatedAtUtc,
    List<ChecklistItem>? items,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      priority: priority ?? this.priority,
      dueAtUtc: clearDueAt ? null : (dueAtUtc ?? this.dueAtUtc),
      isDone: isDone ?? this.isDone,
      manualPosition: manualPosition ?? this.manualPosition,
      lastRemindedAtUtc: lastRemindedAtUtc ?? this.lastRemindedAtUtc,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title.trim(),
      'note': note.trim(),
      'priority': priority.value,
      'due_at_utc': dueAtUtc?.millisecondsSinceEpoch,
      'is_done': isDone ? 1 : 0,
      'manual_position': manualPosition,
      'last_reminded_at_utc': lastRemindedAtUtc?.millisecondsSinceEpoch,
      'created_at_utc': createdAtUtc.millisecondsSinceEpoch,
      'updated_at_utc': updatedAtUtc.millisecondsSinceEpoch,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map, [List<ChecklistItem> items = const []]) {
    final dueMs = map['due_at_utc'] as int?;
    final remindedMs = map['last_reminded_at_utc'] as int?;

    return Todo(
      id: map['id'] as String,
      title: map['title'] as String,
      note: (map['note'] as String?) ?? '',
      priority: TodoPriority.fromValue(map['priority'] as int),
      dueAtUtc: dueMs != null ? DateTime.fromMillisecondsSinceEpoch(dueMs, isUtc: true) : null,
      isDone: (map['is_done'] as int) == 1,
      manualPosition: map['manual_position'] as int,
      lastRemindedAtUtc: remindedMs != null ? DateTime.fromMillisecondsSinceEpoch(remindedMs, isUtc: true) : null,
      createdAtUtc: DateTime.fromMillisecondsSinceEpoch(map['created_at_utc'] as int, isUtc: true),
      updatedAtUtc: DateTime.fromMillisecondsSinceEpoch(map['updated_at_utc'] as int, isUtc: true),
      items: items,
    );
  }
}
