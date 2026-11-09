import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:priority_todo/core/theme/app_theme.dart';
import 'package:priority_todo/features/todos/domain/entities/todo.dart';
import 'package:priority_todo/features/todos/domain/entities/todo_priority.dart';
import 'package:priority_todo/features/todos/presentation/widgets/confirm_delete_dialog.dart';
import 'package:priority_todo/features/todos/presentation/widgets/priority_badge.dart';
import 'package:priority_todo/features/todos/presentation/widgets/strike_text.dart';
import 'package:priority_todo/features/todos/presentation/widgets/todo_list_item.dart';

void main() {
  group('1. StrikeText Bileşeni Testleri (Skill.md)', () {
    testWidgets('Açık görev metni çizgisiz ve beyaz olmalıdır', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StrikeText(text: 'Yapılacak İş', done: false),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('Yapılacak İş'));
      expect(textWidget.style?.decoration, TextDecoration.none);
      expect(textWidget.style?.color, AppTheme.textPrimary);
    });

    testWidgets('Tamamlanmış görev metni çizili ve textDone gri renginde olmalıdır', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StrikeText(text: 'Biten İş', done: true),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('Biten İş'));
      expect(textWidget.style?.decoration, TextDecoration.lineThrough);
      expect(textWidget.style?.color, AppTheme.textDone);
    });

    testWidgets('SelectableStrikeText uzun not için çizik stilini korumalıdır', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SelectableStrikeText(text: 'Uzun açıklama metni…', done: true),
          ),
        ),
      );

      final widget = tester.widget<SelectableText>(find.byType(SelectableText));
      expect(widget.style?.decoration, TextDecoration.lineThrough);
    });
  });

  group('2. PriorityBadge Testleri (design.md)', () {
    testWidgets('Her öncelik seviyesi için etiket ve renk doğru oluşturulmalıdır', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                PriorityBadge(priority: TodoPriority.low),
                PriorityBadge(priority: TodoPriority.normal),
                PriorityBadge(priority: TodoPriority.high),
                PriorityBadge(priority: TodoPriority.critical),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Düşük'), findsOneWidget);
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Yüksek'), findsOneWidget);
      expect(find.text('Kritik'), findsOneWidget);
    });
  });

  group('3. ConfirmDeleteDialog Testleri (FR-02 & Skill.md)', () {
    testWidgets('Silme diyaloğu alt madde sayısıyla birlikte onay istemelidir', (tester) async {
      bool? userChoice;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  userChoice = await ConfirmDeleteDialog.show(
                    context: context,
                    title: 'Proje Raporu',
                    checklistCount: 3,
                  );
                },
                child: const Text('Sil Butonu'),
              ),
            ),
          ),
        ),
      );

      // Diyaloğu aç
      await tester.tap(find.text('Sil Butonu'));
      await tester.pumpAndSettle();

      expect(find.text('Görevi Sil'), findsOneWidget);
      expect(find.text('"Proje Raporu"'), findsOneWidget);
      expect(
        find.text('Bu görev ve 3 alt madde silinecek; işlem geri alınamaz.'),
        findsOneWidget,
      );

      // Vazgeç'e bas
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(userChoice, isFalse);

      // Tekrar aç ve Sil'e bas
      await tester.tap(find.text('Sil Butonu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sil'));
      await tester.pumpAndSettle();
      expect(userChoice, isTrue);
    });
  });

  group('4. TodoListItem Kartı ve Uç Durum Testleri', () {
    testWidgets('Süresi geçmiş görev kırmızı etiketi göstermelidir', (tester) async {
      final nowUtc = DateTime.now().toUtc();
      final overdueTodo = Todo(
        id: '1',
        title: 'Gecikmiş Görev',
        priority: TodoPriority.high,
        dueAtUtc: nowUtc.subtract(const Duration(days: 1)),
        isDone: false,
        manualPosition: 0,
        createdAtUtc: nowUtc,
        updatedAtUtc: nowUtc,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TodoListItem(
              todo: overdueTodo,
              index: 0,
              isReorderable: false,
              onTap: () {},
              onToggle: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Süresi geçti'), findsOneWidget);
    });
  });
}
