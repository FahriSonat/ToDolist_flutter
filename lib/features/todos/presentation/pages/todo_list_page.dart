import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../application/todo_providers.dart';
import '../../application/todo_sort_mode.dart';
import '../../domain/entities/todo_priority.dart';
import '../widgets/todo_list_item.dart';
import 'todo_detail_page.dart';
import 'todo_edit_page.dart';

/// Ana liste ekranı (design.md & project.md)
class TodoListPage extends ConsumerStatefulWidget {
  const TodoListPage({super.key});

  @override
  ConsumerState<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends ConsumerState<TodoListPage> {
  bool _showCompleted = false;

  void _navigateToCreate() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TodoEditPage()),
    );
  }

  void _navigateToDetail(String todoId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TodoDetailPage(todoId: todoId)),
    );
  }

  void _navigateToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todosAsync = _showCompleted
        ? ref.watch(sortedCompletedTodosProvider)
        : ref.watch(sortedOpenTodosProvider);

    final sortMode = ref.watch(todoSortModeProvider);
    final actionController = ref.read(todoActionControllerProvider.notifier);

    // Açık görevler istatistiği
    final openTodosAsync = ref.watch(openTodosStreamProvider);
    final openList = openTodosAsync.asData?.value ?? [];
    final openCount = openList.length;
    final criticalCount = openList
        .where((t) => t.priority == TodoPriority.critical)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bugün'),
        actions: [
          IconButton(
            tooltip: 'Ayarlar',
            icon: const Icon(Icons.settings_outlined, color: AppTheme.textPrimary),
            onPressed: _navigateToSettings,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Özet başlığı
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
            child: Text(
              '$openCount açık görev${criticalCount > 0 ? " · $criticalCount kritik" : ""}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filtreler ve Sıralama Çubuğu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
            child: Row(
              children: [
                // [Açık] sekmesi
                _FilterTab(
                  label: 'Açık',
                  isSelected: !_showCompleted,
                  onTap: () => setState(() => _showCompleted = false),
                ),
                const SizedBox(width: 8),
                // [Tamamlanan] sekmesi
                _FilterTab(
                  label: 'Tamamlanan',
                  isSelected: _showCompleted,
                  onTap: () => setState(() => _showCompleted = true),
                ),
                const Spacer(),
                // Sırala menüsü (yalnızca açık görevlerde)
                if (!_showCompleted)
                  PopupMenuButton<TodoSortMode>(
                    initialValue: sortMode,
                    color: AppTheme.surfaceRaised,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                      side: const BorderSide(color: AppTheme.divider),
                    ),
                    onSelected: (mode) {
                      ref.read(todoSortModeProvider.notifier).setMode(mode);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sort_rounded, size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'Sırala: ${sortMode.label}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary, size: 18),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => TodoSortMode.values.map((mode) {
                      return PopupMenuItem<TodoSortMode>(
                        value: mode,
                        child: Text(
                          mode.label,
                          style: TextStyle(
                            color: mode == sortMode ? AppTheme.textPrimary : AppTheme.textSecondary,
                            fontWeight: mode == sortMode ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(),

          // Görev Listesi / Boş Görünüm
          Expanded(
            child: todosAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.textPrimary),
              ),
              error: (err, _) => Center(
                child: Text('Hata: $err', style: const TextStyle(color: AppTheme.priorityCritical)),
              ),
              data: (todos) {
                if (todos.isEmpty) {
                  return _EmptyState(
                    isCompletedView: _showCompleted,
                    onAddFirstTodo: _navigateToCreate,
                  );
                }

                // Sürükle-bırak sadece açık listede aktiftir
                if (!_showCompleted) {
                  return ReorderableListView.builder(
                    padding: const EdgeInsets.all(AppTheme.pagePadding),
                    itemCount: todos.length,
                    buildDefaultDragHandles: false,
                    // ignore: deprecated_member_use
                    onReorder: (oldIndex, newIndex) {
                      actionController.reorderTodos(todos, oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final todo = todos[index];
                      return TodoListItem(
                        key: ValueKey(todo.id),
                        todo: todo,
                        index: index,
                        isReorderable: true,
                        onTap: () => _navigateToDetail(todo.id),
                        onToggle: (checked) {
                          actionController.toggleTodo(todo.id, checked ?? false);
                        },
                      );
                    },
                  );
                } else {
                  return ListView.builder(
                    padding: const EdgeInsets.all(AppTheme.pagePadding),
                    itemCount: todos.length,
                    itemBuilder: (context, index) {
                      final todo = todos[index];
                      return TodoListItem(
                        key: ValueKey(todo.id),
                        todo: todo,
                        index: index,
                        isReorderable: false,
                        onTap: () => _navigateToDetail(todo.id),
                        onToggle: (checked) {
                          actionController.toggleTodo(todo.id, checked ?? false);
                        },
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreate,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Yeni görev', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.surfaceRaised : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.textPrimary : AppTheme.divider,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isCompletedView;
  final VoidCallback onAddFirstTodo;

  const _EmptyState({
    required this.isCompletedView,
    required this.onAddFirstTodo,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCompletedView ? Icons.check_circle_outline_rounded : Icons.task_alt_rounded,
              size: 64,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isCompletedView
                  ? 'Henüz tamamlanan görev yok.'
                  : 'Bugün için açık görevin yok.',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isCompletedView
                  ? 'Tamamladığın görevler burada arşivlenir.'
                  : 'Önemli işlerini planlamak için hemen bir görev oluştur.',
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (!isCompletedView) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAddFirstTodo,
                icon: const Icon(Icons.add_rounded),
                label: const Text('İlk görevini ekle'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
