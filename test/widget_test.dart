import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/auth/data/auth_repository.dart';

void main() {
  testWidgets('renders the authentication screen', (WidgetTester tester) async {
    final repository = AuthRepository(
      ApiClient(baseUrl: 'http://localhost:8080/api/v1'),
    );
    await tester.pumpWidget(TodoApp(repository: repository));

    expect(find.text('Todo App'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
