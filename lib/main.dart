import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/router/app_router.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/adaptive_theme_provider.dart';
import 'features/auth_and_dashboard/providers/auth_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await initializeDateFormatting('vi_VN', null);
  } catch (e) {
    debugPrint('Init date formatting error: $e');
  }

  await LocalStorageService.init();
  await NotificationService.init();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init error (may run in offline mode): $e');
  }

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
    ref.listen<AdaptiveState>(adaptiveStateProvider, (previous, next) {
      final auth = ref.read(authProvider);
      final isAuth = auth.status == AuthStatus.authenticated;
      final notifyOverload = auth.user?.notifyOnOverload ?? true;

      if (next.mode == AdaptiveMode.overload) {
        NotificationService.checkAndNotifyOverload(
          taskCount: next.activeTaskCount,
          threshold: next.backlogThreshold,
          isEnabled: isAuth && notifyOverload,
        );
      } else if (previous != null &&
          previous.mode == AdaptiveMode.overload &&
          next.mode != AdaptiveMode.overload) {
        NotificationService.cancelOverloadAlert();
      }
    });

    final theme = ref.watch(adaptiveThemeProvider);

    return MaterialApp.router(
      title: 'Smart Workflow & Adaptive Todo App',
      debugShowCheckedModeBanner: false,
      theme: theme,
      themeAnimationDuration: const Duration(milliseconds: 500),
      themeAnimationCurve: Curves.easeInOutCubic,
      routerConfig: appRouter,
    );
  }
}
