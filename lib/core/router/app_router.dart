import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth_and_dashboard/presentation/analytics_dashboard_screen.dart';
import '../../features/auth_and_dashboard/presentation/login_register_screen.dart';
import '../../features/auth_and_dashboard/presentation/profile_settings_screen.dart';
import '../../features/auth_and_dashboard/presentation/splash_screen.dart';
import '../../features/task_board_and_filter/presentation/task_board_screen.dart';
import '../../features/task_detail_and_collab/presentation/task_detail_screen.dart';

CustomTransitionPage _buildPageWithTransition({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.05, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      );
    },
  );
}

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const SplashScreen(),
      ),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const LoginRegisterScreen(),
      ),
    ),
    GoRoute(
      path: '/dashboard',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const AnalyticsDashboardScreen(),
      ),
    ),
    GoRoute(
      path: '/profile',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const ProfileSettingsScreen(),
      ),
    ),
    GoRoute(
      path: '/board',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const TaskBoardScreen(),
      ),
    ),
    GoRoute(
      path: '/task-detail/:id',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: TaskDetailScreen(taskId: state.pathParameters['id']!),
      ),
    ),
  ],
);
