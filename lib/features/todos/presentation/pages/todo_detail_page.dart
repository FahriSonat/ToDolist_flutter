import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_date_format.dart';
import '../../application/todo_providers.dart';
import '../../domain/entities/checklist_item.dart';
import '../../domain/entities/todo.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/priority_badge.dart';
import '../widgets/strike_text.dart';
import 'todo_edit_page.dart';

/// Görev Detay Ekranı (design.md & Skill.md)
class TodoDetailPage extends ConsumerStatefulWidget {
  final String todoId;

  const TodoDetailPage({super.key, required this.todoId});

  @override
  ConsumerState<TodoDetailPage> createState() => _TodoDetailPageState();
}

class _TodoDetailPageState extends ConsumerState<TodoDetailPage> {
  final _quickItemController = TextEditingController();
  bool _isAddingItem = false;

  @override
  void dispose() {
    _quickItemController.dispose();
    super.dispose();
  }

  String _formatDetailDate(DateTime dueAtUtc) {
    return AppDateFormat.formatRelative(dueAtUtc, fullFormat: true);
  }

  Future<void> _handleDelete(Todo todo) async {
    final confirmed = await ConfirmDeleteDialog.show(
      context: context,
      title: todo.title,
      checklistCount: todo.items.length,
    );

    if (!confirmed || !mounted) return;

    final success = await ref
        .read(todoActionControllerProvider.notifier)
        .deleteTodo(todo.id);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
    } else {
      final err = ref.read(todoActionControllerProvider).errorMessage ?? 'Silme başarısız';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppTheme.priorityCritical),
      );
    }
  }

  Future<void> _addQuickChecklistItem(Todo todo) async {
    final text = _quickItemController.text.trim();
    if (text.isEmpty || text.length > 500) return;

    final item = ChecklistItem(
      id: const Uuid().v4(),
      todoId: todo.id,
      text: text,
      isDone: false,
      position: todo.items.length,
    );

    _quickItemController.clear();
    setState(() => _isAddingItem = false);

    await ref.read(todoActionControllerProvider.notifier).addChecklistItem(item);
  }

  @override
  Widget build(BuildContext context) {
    final todoAsync = ref.watch(todoDetailProvider(widget.todoId));
    final actionController = ref.read(todoActionControllerProvider.notifier);
    final actionState = ref.watch(todoActionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Geri',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Görev Detayı'),
        actions: [
          todoAsync.when(
            data: (todo) {
              if (todo == null) return const SizedBox.shrink();
              return Row(
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TodoEditPage(initialTodo: todo),
                        ),
                      );
                    },
                    child: const Text('Düzenle'),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.priorityCritical,
                    ),
                    onPressed: () => _handleDelete(todo),
                    child: const Text('Sil'),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: todoAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.textPrimary),
        ),
        error: (err, _) => Center(
          child: Text('Hata: $err', style: const TextStyle(color: AppTheme.priorityCritical)),
        ),
        data: (todo) {
          if (todo == null) {
            return const Center(
              child: Text(
                'Görev bulunamadı veya silinmiş.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }

          final isOverdue = todo.isOverdue(DateTime.now().toUtc());

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ana Görev Başlığı ve Tamamlama Kutusu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: AppTheme.minTouchTarget,
                      height: AppTheme.minTouchTarget,
                      child: Center(
                        child: Checkbox(
                          value: todo.isDone,
                          onChanged: actionState.isSaving
                              ? null
                              : (checked) {
                                  actionController.toggleTodo(
                                    todo.id,
                                    checked ?? false,
                                  );
                                },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: StrikeText(
                          text: todo.title,
                          done: todo.isDone,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Öncelik ve Tarih Rozetleri
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Row(
                    children: [
                      PriorityBadge(priority: todo.priority),
                      const SizedBox(width: 12),
                      if (todo.dueAtUtc != null) ...[
                        Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: isOverdue ? AppTheme.priorityCritical : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDetailDate(todo.dueAtUtc!),
                          style: TextStyle(
                            color: isOverdue ? AppTheme.priorityCritical : AppTheme.textSecondary,
                            fontSize: 14,
                            fontWeight: isOverdue ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        if (isOverdue) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.priorityCritical.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Süresi geçti',
                              style: TextStyle(
                                color: AppTheme.priorityCritical,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // NOT BÖLÜMÜ (FR-10: Ana görev tamamlanınca uzun not da çizilir)
                const Text(
                  'NOT',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 80),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: todo.note.trim().isNotEmpty
                      ? SelectableStrikeText(
                          text: todo.note,
                          done: todo.isDone,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                          ),
                        )
                      : const Text(
                          'Eklenmiş bir açıklama veya not yok.',
                          style: TextStyle(
                            color: AppTheme.textDone,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                ),

                const SizedBox(height: 28),
                const Divider(),
                const SizedBox(height: 16),

                // KONTROL LİSTESİ BÖLÜMÜ
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'KONTROL LİSTESİ',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      '${todo.completedItemsCount}/${todo.totalItemsCount}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Maddeler
                if (todo.items.isEmpty && !_isAddingItem)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Bu görev için kontrol listesi maddesi yok.',
                      style: TextStyle(color: AppTheme.textDone, fontStyle: FontStyle.italic),
                    ),
                  )
                else
                  ...todo.items.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: CheckboxListTile(
                        value: item.isDone,
                        onChanged: actionState.isSaving
                            ? null
                            : (checked) {
                                actionController.toggleChecklistItem(
                                  todoId: todo.id,
                                  itemId: item.id,
                                  isDone: checked ?? false,
                                );
                              },
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppTheme.textPrimary,
                        checkColor: AppTheme.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                        title: StrikeText(
                          text: item.text,
                          done: item.isDone,
                          style: const TextStyle(fontSize: 15),
                        ),
                        secondary: IconButton(
                          tooltip: 'Maddeyi Sil',
                          icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textSecondary),
                          onPressed: () {
                            actionController.deleteChecklistItem(
                              todoId: todo.id,
                              itemId: item.id,
                            );
                          },
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 12),

                // Madde Ekle Butonu veya Giriş Alanı
                if (_isAddingItem)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceRaised,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                      border: Border.all(color: AppTheme.textSecondary),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _quickItemController,
                            autofocus: true,
                            maxLength: 500,
                            decoration: const InputDecoration(
                              hintText: 'Yeni alt madde…',
                              counterText: '',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                            ),
                            onSubmitted: (_) => _addQuickChecklistItem(todo),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.check_rounded, color: AppTheme.textPrimary),
                          onPressed: () => _addQuickChecklistItem(todo),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                          onPressed: () {
                            _quickItemController.clear();
                            setState(() => _isAddingItem = false);
                          },
                        ),
                      ],
                    ),
                  )
                else
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      side: const BorderSide(color: AppTheme.divider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                      ),
                    ),
                    onPressed: () => setState(() => _isAddingItem = true),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Madde ekle'),
                  ),

                const SizedBox(height: 48),
              ],
            ),
          );
        },
      ),
    );
  }
}
