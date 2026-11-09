import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'bootstrap.dart';
import 'core/theme/app_theme.dart';
import 'features/todos/presentation/pages/todo_list_page.dart';

void main() async {
  final container = await bootstrap();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const PriorityTodoApp(),
    ),
  );
}

class PriorityTodoApp extends StatelessWidget {
  const PriorityTodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Priority Todo',
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const TodoListPage(),
    );
  }
}
