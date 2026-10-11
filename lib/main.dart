import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_page.dart';

void main() {
  final client = ApiClient(baseUrl: AppConfig.apiBaseUrl);
  runApp(TodoApp(repository: AuthRepository(client)));
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key, required this.repository});

  final AuthRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: AuthPage(repository: repository),
    );
  }
}
