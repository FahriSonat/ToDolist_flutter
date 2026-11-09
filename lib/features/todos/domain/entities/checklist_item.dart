/// Kontrol listesi alt maddesi varlığı (architucture.md)
class ChecklistItem {
  final String id;
  final String todoId;
  final String text;
  final bool isDone;
  final int position;

  const ChecklistItem({
    required this.id,
    required this.todoId,
    required this.text,
    this.isDone = false,
    required this.position,
  });

  ChecklistItem copyWith({
    String? id,
    String? todoId,
    String? text,
    bool? isDone,
    int? position,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      todoId: todoId ?? this.todoId,
      text: text ?? this.text,
      isDone: isDone ?? this.isDone,
      position: position ?? this.position,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'todo_id': todoId,
      'text': text.trim(),
      'is_done': isDone ? 1 : 0,
      'position': position,
    };
  }

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id'] as String,
      todoId: map['todo_id'] as String,
      text: map['text'] as String,
      isDone: (map['is_done'] as int) == 1,
      position: map['position'] as int,
    );
  }
}
