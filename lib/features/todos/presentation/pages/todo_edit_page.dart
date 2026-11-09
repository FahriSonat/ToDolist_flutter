import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../application/todo_providers.dart';
import '../../domain/entities/checklist_item.dart';
import '../../domain/entities/todo.dart';
import '../../domain/entities/todo_priority.dart';

/// Görev Editörü ekranı (Yeni görev ekleme / Düzenleme)
class TodoEditPage extends ConsumerStatefulWidget {
  final Todo? initialTodo;

  const TodoEditPage({super.key, this.initialTodo});

  @override
  ConsumerState<TodoEditPage> createState() => _TodoEditPageState();
}

class _TodoEditPageState extends ConsumerState<TodoEditPage> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _itemController = TextEditingController();

  late TodoPriority _priority;
  DateTime? _selectedDueLocal;
  late List<ChecklistItem> _checklistItems;
  bool _canSave = false;

  bool get _isEditing => widget.initialTodo != null;

  @override
  void initState() {
    super.initState();
    final todo = widget.initialTodo;
    if (todo != null) {
      _titleController.text = todo.title;
      _noteController.text = todo.note;
      _priority = todo.priority;
      _selectedDueLocal = todo.dueAtUtc?.toLocal();
      _checklistItems = List<ChecklistItem>.from(todo.items);
      _canSave = todo.title.trim().isNotEmpty;
    } else {
      _priority = TodoPriority.normal;
      _checklistItems = [];
      _canSave = false;
    }

    _titleController.addListener(_onTitleChanged);
  }

  void _onTitleChanged() {
    final valid = _titleController.text.trim().isNotEmpty &&
        _titleController.text.trim().length <= 160;
    if (valid != _canSave) {
      setState(() => _canSave = valid);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _itemController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final initial = _selectedDueLocal ?? now;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: AppTheme.darkTheme,
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    final initialTime = _selectedDueLocal != null
        ? TimeOfDay(hour: _selectedDueLocal!.hour, minute: _selectedDueLocal!.minute)
        : const TimeOfDay(hour: 12, minute: 0);

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: AppTheme.darkTheme,
          child: child!,
        );
      },
    );

    if (pickedTime == null || !mounted) return;

    setState(() {
      _selectedDueLocal = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _clearDueDate() {
    setState(() => _selectedDueLocal = null);
  }

  void _addChecklistItem() {
    final text = _itemController.text.trim();
    if (text.isEmpty || text.length > 500) return;

    final newItem = ChecklistItem(
      id: const Uuid().v4(),
      todoId: widget.initialTodo?.id ?? '',
      text: text,
      isDone: false,
      position: _checklistItems.length,
    );

    setState(() {
      _checklistItems.add(newItem);
      _itemController.clear();
    });
  }

  void _removeChecklistItem(int index) {
    setState(() {
      _checklistItems.removeAt(index);
      for (int i = 0; i < _checklistItems.length; i++) {
        _checklistItems[i] = _checklistItems[i].copyWith(position: i);
      }
    });
  }

  Future<void> _save() async {
    if (!_canSave) return;

    final title = _titleController.text.trim();
    final note = _noteController.text.trim();
    final nowUtc = DateTime.now().toUtc();
    final dueUtc = _selectedDueLocal?.toUtc();

    final actionController = ref.read(todoActionControllerProvider.notifier);

    final String todoId = widget.initialTodo?.id ?? const Uuid().v4();

    // Checklist maddelerinin todoId'sini eşitle
    final syncedItems = _checklistItems.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return item.copyWith(todoId: todoId, position: index);
    }).toList();

    bool success;
    if (_isEditing) {
      final updatedTodo = widget.initialTodo!.copyWith(
        title: title,
        note: note,
        priority: _priority,
        dueAtUtc: dueUtc,
        clearDueAt: dueUtc == null,
        updatedAtUtc: nowUtc,
        items: syncedItems,
      );
      success = await actionController.updateTodo(updatedTodo);
    } else {
      // Açık görev sayısına göre manual_position ver
      final openCount = ref.read(openTodosStreamProvider).asData?.value.length ?? 0;
      final newTodo = Todo(
        id: todoId,
        title: title,
        note: note,
        priority: _priority,
        dueAtUtc: dueUtc,
        isDone: false,
        manualPosition: openCount,
        createdAtUtc: nowUtc,
        updatedAtUtc: nowUtc,
        items: syncedItems,
      );
      success = await actionController.saveTodo(newTodo);
    }

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
    } else {
      final err = ref.read(todoActionControllerProvider).errorMessage ?? 'Hata oluştu';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppTheme.priorityCritical,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(todoActionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Görevi Düzenle' : 'Yeni Görev'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: _canSave && !actionState.isSaving ? _save : null,
              child: actionState.isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textPrimary),
                    )
                  : Text(
                      'Kaydet',
                      style: TextStyle(
                        color: _canSave ? AppTheme.textPrimary : AppTheme.textDone,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık Girişi
            TextField(
              controller: _titleController,
              autofocus: !_isEditing,
              maxLength: 160,
              maxLines: null,
              keyboardType: TextInputType.text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              decoration: const InputDecoration(
                labelText: 'Görev Başlığı *',
                hintText: 'Örn: Sunum taslağını bitir',
                counterStyle: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 16),

            // Öncelik Seçici
            const Text(
              'ÖNCELİK',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: TodoPriority.values.map((p) {
                final isSelected = _priority == p;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(() => _priority = p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? p.color.withValues(alpha: 0.2)
                              : AppTheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? p.color : AppTheme.divider,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(p.icon, color: isSelected ? p.color : AppTheme.textSecondary, size: 18),
                            const SizedBox(height: 4),
                            Text(
                              p.label,
                              style: TextStyle(
                                color: isSelected ? p.color : AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Son Tarih & Saat
            const Text(
              'SON TARİH VE SAAT (OPSİYONEL)',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_outlined, color: AppTheme.textSecondary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _selectedDueLocal != null
                          ? DateFormat('d MMMM yyyy, HH:mm', 'tr_TR').format(_selectedDueLocal!)
                          : 'Tarih seçilmedi',
                      style: TextStyle(
                        color: _selectedDueLocal != null
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (_selectedDueLocal != null)
                    IconButton(
                      tooltip: 'Tarihi Kaldır',
                      icon: const Icon(Icons.clear_rounded, size: 20, color: AppTheme.textSecondary),
                      onPressed: _clearDueDate,
                    ),
                  TextButton(
                    onPressed: _pickDueDate,
                    child: Text(_selectedDueLocal != null ? 'Değiştir' : 'Seç'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Uzun Not Alanı
            const Text(
              'UZUN NOT',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 6,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'Detaylı görev açıklaması, bağlantılar veya referanslar…',
              ),
            ),
            const SizedBox(height: 24),

            // Kontrol Listesi (Checklist)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'KONTROL LİSTESİ',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '${_checklistItems.length} madde',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Yeni madde ekleme kutusu
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _itemController,
                    maxLength: 500,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addChecklistItem(),
                    decoration: const InputDecoration(
                      hintText: 'Madde ekle…',
                      counterText: '',
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.surfaceRaised,
                    foregroundColor: AppTheme.textPrimary,
                  ),
                  onPressed: _addChecklistItem,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Liste maddeleri
            if (_checklistItems.isNotEmpty)
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: true,
                itemCount: _checklistItems.length,
                // ignore: deprecated_member_use
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _checklistItems.removeAt(oldIndex);
                    _checklistItems.insert(newIndex, item);
                    for (int i = 0; i < _checklistItems.length; i++) {
                      _checklistItems[i] = _checklistItems[i].copyWith(position: i);
                    }
                  });
                },
                itemBuilder: (context, index) {
                  final item = _checklistItems[index];
                  return Container(
                    key: ValueKey(item.id),
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.text,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Maddeyi Sil',
                          icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textSecondary),
                          onPressed: () => _removeChecklistItem(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
