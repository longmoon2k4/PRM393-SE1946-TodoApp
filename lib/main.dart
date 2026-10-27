import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/router/app_router.dart';
import 'package:todo_app/core/theme/adaptive_theme_provider.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(adaptiveThemeProvider);

    return MaterialApp.router(
      title: 'Smart Workflow Todo App',
      theme: theme,
      routerConfig: appRouter,
    );
  }
}
