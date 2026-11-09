import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:priority_todo/core/clock/clock.dart';
import 'package:priority_todo/features/settings/application/settings_notifier.dart';
import 'package:priority_todo/features/settings/domain/settings_entity.dart';
import 'package:priority_todo/features/todos/data/repositories/sqlite_todo_repository.dart';
import 'package:priority_todo/features/todos/domain/entities/checklist_item.dart';
import 'package:priority_todo/features/todos/domain/entities/todo.dart';
import 'package:priority_todo/features/todos/domain/repositories/todo_repository.dart';
import 'package:priority_todo/platform/notification/notification_service.dart';
import 'reminder_scheduler.dart';
import 'todo_sort_mode.dart';

final clockProvider = Provider<Clock>((ref) => const SystemClock());

final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  final clock = ref.watch(clockProvider);
  return SqliteTodoRepository(clock: clock);
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) {
  final repo = ref.watch(todoRepositoryProvider);
  final notif = ref.watch(notificationServiceProvider);
  final clock = ref.watch(clockProvider);
  return ReminderScheduler(
    repository: repo,
    notificationService: notif,
    clock: clock,
  );
});

class TodoSortModeNotifier extends Notifier<TodoSortMode> {
  @override
  TodoSortMode build() => TodoSortMode.priority;

  void setMode(TodoSortMode mode) => state = mode;
}

final todoSortModeProvider =
    NotifierProvider<TodoSortModeNotifier, TodoSortMode>(TodoSortModeNotifier.new);

/// Açık görevleri dinleyen akış provider'ı
final openTodosStreamProvider = StreamProvider<List<Todo>>((ref) {
  final repo = ref.watch(todoRepositoryProvider);
  return repo.watchTodos(isDone: false);
});

/// Tamamlanmış görevleri dinleyen akış provider'ı
final completedTodosStreamProvider = StreamProvider<List<Todo>>((ref) {
  final repo = ref.watch(todoRepositoryProvider);
  return repo.watchTodos(isDone: true);
});

/// Sıralanmış açık görevler
final sortedOpenTodosProvider = Provider<AsyncValue<List<Todo>>>((ref) {
  final todosAsync = ref.watch(openTodosStreamProvider);
  final sortMode = ref.watch(todoSortModeProvider);
  final clock = ref.watch(clockProvider);

  return todosAsync.whenData((todos) {
    return sortMode.sort(todos, clock.nowUtc());
  });
});

/// Sıralanmış tamamlanan görevler (Tamamlananlar her zaman tamamlanma/oluşturulma sırasına göre)
final sortedCompletedTodosProvider = Provider<AsyncValue<List<Todo>>>((ref) {
  final todosAsync = ref.watch(completedTodosStreamProvider);
  final clock = ref.watch(clockProvider);

  return todosAsync.whenData((todos) {
    return TodoSortMode.priority.sort(todos, clock.nowUtc());
  });
});

/// Tekil görev detay sağlayıcısı
final todoDetailProvider = StreamProvider.family<Todo?, String>((ref, id) {
  final repo = ref.watch(todoRepositoryProvider);
  return repo.watchTodos(isDone: false).asyncMap((_) => repo.getTodoById(id));
});

class TodoActionState {
  final bool isSaving;
  final String? errorMessage;

  const TodoActionState({this.isSaving = false, this.errorMessage});

  TodoActionState copyWith({bool? isSaving, String? errorMessage}) {
    return TodoActionState(
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }
}

class TodoActionController extends Notifier<TodoActionState> {
  @override
  TodoActionState build() {
    return const TodoActionState();
  }

  TodoRepository get _repo => ref.read(todoRepositoryProvider);
  ReminderScheduler get _scheduler => ref.read(reminderSchedulerProvider);
  SettingsEntity get _settings =>
      ref.read(settingsNotifierProvider).asData?.value ?? const SettingsEntity();

  Future<bool> saveTodo(Todo todo) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await _repo.saveTodo(todo);
      await _scheduler.onTodoSaved(todo, _settings);
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateTodo(Todo todo) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await _repo.updateTodo(todo);
      await _scheduler.onTodoSaved(todo, _settings);
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteTodo(String id) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await _repo.deleteTodo(id);
      await _scheduler.onTodoDeleted(id);
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> toggleTodo(String id, bool isDone) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await _repo.toggleTodoDone(id, isDone);
      final updated = await _repo.getTodoById(id);
      if (updated != null) {
        await _scheduler.onTodoToggled(updated, _settings);
      }
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> toggleChecklistItem({
    required String todoId,
    required String itemId,
    required bool isDone,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await _repo.toggleChecklistItem(
        todoId: todoId,
        itemId: itemId,
        isDone: isDone,
      );
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> addChecklistItem(ChecklistItem item) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await _repo.addChecklistItem(item);
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteChecklistItem({
    required String todoId,
    required String itemId,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await _repo.deleteChecklistItem(todoId: todoId, itemId: itemId);
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Sürükle-bırak (Skill.md kuralı)
  Future<bool> reorderTodos(List<Todo> todos, int oldIndex, int newIndex) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final copy = List<Todo>.from(todos);
      if (newIndex > oldIndex) newIndex -= 1;
      final moved = copy.removeAt(oldIndex);
      copy.insert(newIndex, moved);

      // Sıralama modu otomatik olarak 'Özel sıra' yapılır
      ref.read(todoSortModeProvider.notifier).setMode(TodoSortMode.manual);

      final orderedIds = copy.map((t) => t.id).toList();
      await _repo.reorderTodos(orderedIds);
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> clearAllData() async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await _repo.clearAllData();
      await ref.read(notificationServiceProvider).cancelAllNotifications();
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }
}

final todoActionControllerProvider =
    NotifierProvider<TodoActionController, TodoActionState>(TodoActionController.new);
