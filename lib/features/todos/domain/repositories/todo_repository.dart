import '../entities/checklist_item.dart';
import '../entities/todo.dart';

/// Todo repository arayüzü (Skill.md & architucture.md)
abstract class TodoRepository {
  /// Açık veya tamamlanmış görevleri akış olarak dinler
  Stream<List<Todo>> watchTodos({required bool isDone});

  /// Açık veya tamamlanmış görevleri tek seferlik getirir
  Future<List<Todo>> getTodos({required bool isDone});

  /// Tüm açık ve yüksek/kritik görevleri getirir (hatırlatma servisi için)
  Future<List<Todo>> getUrgentPendingTodos();

  /// Tekil görevi checklist maddeleriyle birlikte getirir
  Future<Todo?> getTodoById(String id);

  /// Yeni görevi alt maddeleriyle birlikte transaction içinde kaydeder
  Future<void> saveTodo(Todo todo);

  /// Görevi ve alt maddelerini günceller
  Future<void> updateTodo(Todo todo);

  /// Görevi ve tüm alt maddelerini cascade delete ile siler
  Future<void> deleteTodo(String id);

  /// Görevin tamamlama durumunu günceller
  Future<void> toggleTodoDone(String id, bool isDone);

  /// Belirli bir checklist maddesinin tamamlama durumunu günceller
  Future<void> toggleChecklistItem({
    required String todoId,
    required String itemId,
    required bool isDone,
  });

  /// Kontrol listesine yeni madde ekler
  Future<void> addChecklistItem(ChecklistItem item);

  /// Kontrol listesinden madde siler
  Future<void> deleteChecklistItem({
    required String todoId,
    required String itemId,
  });

  /// Manuel sıralamayı (manual_position) günceller
  Future<void> reorderTodos(List<String> orderedTodoIds);

  /// Kontrol listesi maddelerinin sırasını günceller
  Future<void> reorderChecklistItems(String todoId, List<String> orderedItemIds);

  /// Görevin son bildirim zamanını günceller
  Future<void> updateLastRemindedAt(String id, DateTime remindedAtUtc);

  /// Tüm verileri temizler (Ayarlar -> Sıfırlama)
  Future<void> clearAllData();
}
