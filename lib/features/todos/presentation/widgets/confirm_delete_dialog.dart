import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Silme onay iletişim kutusu (design.md & Skill.md)
class ConfirmDeleteDialog extends StatelessWidget {
  final String title;
  final int checklistCount;

  const ConfirmDeleteDialog({
    super.key,
    required this.title,
    required this.checklistCount,
  });

  static Future<bool> show({
    required BuildContext context,
    required String title,
    required int checklistCount,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmDeleteDialog(
        title: title,
        checklistCount: checklistCount,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final message = checklistCount > 0
        ? 'Bu görev ve $checklistCount alt madde silinecek; işlem geri alınamaz.'
        : 'Bu görev silinecek; işlem geri alınamaz.';

    return AlertDialog(
      title: const Text('Görevi Sil'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"$title"',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(message),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Vazgeç'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.priorityCritical,
            foregroundColor: AppTheme.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Sil'),
        ),
      ],
    );
  }
}
