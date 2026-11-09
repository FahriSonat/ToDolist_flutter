import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Tamamlama / çizik bileşeni (Skill.md)
class StrikeText extends StatelessWidget {
  const StrikeText({
    super.key,
    required this.text,
    required this.done,
    this.style,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final bool done;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.bodyLarge!;
    return Text(
      text,
      softWrap: true,
      maxLines: maxLines,
      overflow: overflow,
      style: base.copyWith(
        color: done ? AppTheme.textDone : AppTheme.textPrimary,
        decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
        decorationColor: AppTheme.textDone,
        decorationThickness: 1.5,
      ),
    );
  }
}

/// Uzun not için seçilebilir çizik bileşeni (Skill.md)
class SelectableStrikeText extends StatelessWidget {
  const SelectableStrikeText({
    super.key,
    required this.text,
    required this.done,
    this.style,
  });

  final String text;
  final bool done;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.bodyMedium!;
    return SelectableText(
      text,
      style: base.copyWith(
        color: done ? AppTheme.textDone : AppTheme.textPrimary,
        decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
        decorationColor: AppTheme.textDone,
        decorationThickness: 1.5,
      ),
    );
  }
}
