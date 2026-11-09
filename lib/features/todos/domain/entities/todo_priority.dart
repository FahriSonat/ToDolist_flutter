import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Görev öncelik seviyeleri (1: Düşük, 2: Normal, 3: Yüksek, 4: Kritik)
enum TodoPriority {
  low(1, 'Düşük', AppTheme.priorityLow, Icons.arrow_downward_rounded),
  normal(2, 'Normal', AppTheme.priorityNormal, Icons.remove_rounded),
  high(3, 'Yüksek', AppTheme.priorityHigh, Icons.arrow_upward_rounded),
  critical(4, 'Kritik', AppTheme.priorityCritical, Icons.priority_high_rounded);

  final int value;
  final String label;
  final Color color;
  final IconData icon;

  const TodoPriority(this.value, this.label, this.color, this.icon);

  static TodoPriority fromValue(int value) {
    return TodoPriority.values.firstWhere(
      (p) => p.value == value,
      orElse: () => TodoPriority.normal,
    );
  }
}
