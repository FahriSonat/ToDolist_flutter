import 'package:flutter/material.dart';
import '../../domain/entities/todo_priority.dart';

/// Öncelik rozeti (design.md)
class PriorityBadge extends StatelessWidget {
  final TodoPriority priority;
  final bool compact;

  const PriorityBadge({
    super.key,
    required this.priority,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: priority.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            priority.label,
            style: TextStyle(
              color: priority.color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: priority.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: priority.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(priority.icon, size: 14, color: priority.color),
          const SizedBox(width: 4),
          Text(
            priority.label,
            style: TextStyle(
              color: priority.color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
