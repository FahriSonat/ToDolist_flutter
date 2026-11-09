import '../domain/entities/todo.dart';

/// Görev sıralama modları (project.md)
enum TodoSortMode {
  priority('Öncelik', 'Kritik görevler en başta'),
  dueAt('Son Tarih', 'En yakın tarih en başta'),
  manual('Özel sıra', 'Sürükle-bırak ile belirlenen sıra');

  final String label;
  final String description;

  const TodoSortMode(this.label, this.description);

  /// Görev listesini seçilen moda göre sıralar
  List<Todo> sort(List<Todo> todos, DateTime nowUtc) {
    final list = List<Todo>.from(todos);

    switch (this) {
      case TodoSortMode.priority:
        // Varsayılan sıralama: önem (kritik ilk), son tarih (yakın ilk), manuel sıra
        list.sort((a, b) {
          // 1. Önem (Kritik 4 -> Düşük 1)
          final pComp = b.priority.value.compareTo(a.priority.value);
          if (pComp != 0) return pComp;

          // 2. Son tarih (yakın olan önce; tarihi olan tarihi olmayandan önce)
          if (a.dueAtUtc != null && b.dueAtUtc != null) {
            final dComp = a.dueAtUtc!.compareTo(b.dueAtUtc!);
            if (dComp != 0) return dComp;
          } else if (a.dueAtUtc != null) {
            return -1;
          } else if (b.dueAtUtc != null) {
            return 1;
          }

          // 3. Manuel sıra
          return a.manualPosition.compareTo(b.manualPosition);
        });
        return list;

      case TodoSortMode.dueAt:
        list.sort((a, b) {
          if (a.dueAtUtc != null && b.dueAtUtc != null) {
            final dComp = a.dueAtUtc!.compareTo(b.dueAtUtc!);
            if (dComp != 0) return dComp;
          } else if (a.dueAtUtc != null) {
            return -1;
          } else if (b.dueAtUtc != null) {
            return 1;
          }

          final pComp = b.priority.value.compareTo(a.priority.value);
          if (pComp != 0) return pComp;

          return a.manualPosition.compareTo(b.manualPosition);
        });
        return list;

      case TodoSortMode.manual:
        list.sort((a, b) => a.manualPosition.compareTo(b.manualPosition));
        return list;
    }
  }
}
