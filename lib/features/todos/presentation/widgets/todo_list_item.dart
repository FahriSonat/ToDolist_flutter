import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/todo.dart';
import 'priority_badge.dart';
import 'strike_text.dart';

/// Görev kartı bileşeni (design.md & Skill.md)
class TodoListItem extends StatelessWidget {
  final Todo todo;
  final int index;
  final bool isReorderable;
  final VoidCallback onTap;
  final ValueChanged<bool?> onToggle;

  const TodoListItem({
    super.key,
    required this.todo,
    required this.index,
    required this.isReorderable,
    required this.onTap,
    required this.onToggle,
  });

  String _formatDueDate(DateTime dueAtUtc) {
    final local = dueAtUtc.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(local.year, local.month, local.day);

    final timeStr = DateFormat('HH:mm').format(local);
    if (dueDay == today) {
      return 'Bugün $timeStr';
    } else if (dueDay == today.add(const Duration(days: 1))) {
      return 'Yarın $timeStr';
    } else if (dueDay == today.subtract(const Duration(days: 1))) {
      return 'Dün $timeStr';
    } else {
      return DateFormat('d MMM, HH:mm', 'tr_TR').format(local);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = todo.isOverdue(DateTime.now().toUtc());

    return Semantics(
      label: 'Görev: ${todo.title}, ${todo.isDone ? "tamamlandı" : "tamamlanmadı"}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          border: Border.all(color: AppTheme.divider, width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Sürükleme Tutamacı (Sadece Reorderable modda veya genel)
                  if (isReorderable)
                    ReorderableDragStartListener(
                      index: index,
                      child: Semantics(
                        label: 'Sıralamayı değiştir',
                        button: true,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: AppTheme.minTouchTarget,
                            minHeight: AppTheme.minTouchTarget,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.drag_indicator_rounded,
                            color: AppTheme.textSecondary,
                            size: 22,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 8),

                  // Tamamlama Kutucuğu
                  SizedBox(
                    width: AppTheme.minTouchTarget,
                    height: AppTheme.minTouchTarget,
                    child: Center(
                      child: Checkbox(
                        value: todo.isDone,
                        onChanged: onToggle,
                      ),
                    ),
                  ),

                  const SizedBox(width: 4),

                  // Görev İçeriği
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StrikeText(
                          text: todo.title,
                          done: todo.isDone,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // Tarih / Süresi Geçti
                            if (todo.dueAtUtc != null) ...[
                              if (isOverdue)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  margin: const EdgeInsets.only(right: 6),
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
                                )
                              else
                                Text(
                                  _formatDueDate(todo.dueAtUtc!),
                                  style: TextStyle(
                                    color: todo.isDone
                                        ? AppTheme.textDone
                                        : AppTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              const Text(' · ', style: TextStyle(color: AppTheme.textSecondary)),
                            ],
                            // Öncelik
                            PriorityBadge(priority: todo.priority, compact: true),
                            // Alt madde sayısı
                            if (todo.hasChecklist) ...[
                              const Text(' · ', style: TextStyle(color: AppTheme.textSecondary)),
                              Text(
                                '${todo.completedItemsCount}/${todo.totalItemsCount} alt madde',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
