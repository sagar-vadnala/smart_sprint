import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_sprint/features/auth/bloc/auth_bloc.dart';
import 'package:smart_sprint/features/auth/view/login_screen.dart';
import 'package:smart_sprint/features/auth/view/signup_screen.dart';
import 'package:smart_sprint/features/nav/view/main_shell.dart';
import 'package:smart_sprint/features/onboarding/view/onboarding_screen.dart';
import 'package:smart_sprint/features/profile/view/profile_screen.dart';
import 'package:smart_sprint/features/search/view/search_screen.dart';
import 'package:smart_sprint/features/splash/cubit/splash_cubit.dart';
import 'package:smart_sprint/features/splash/view/splash_screen.dart';
import 'package:smart_sprint/features/workspace/view/project_detail_screen.dart';
import 'package:smart_sprint/features/workspace/view/task_detail_screen.dart';

Widget _slideUp(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(
    opacity: animation,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
      child: child,
    ),
  );
}

abstract final class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (_) => SplashCubit(),
            child: const SplashScreen(),
          ),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          transitionsBuilder: (_, _, _, child) => child,
        ),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (_) => AuthBloc(),
            child: const LoginScreen(),
          ),
          transitionDuration: const Duration(milliseconds: 420),
          transitionsBuilder: (_, animation, _, child) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  ),
              child: child,
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (_) => AuthBloc(),
            child: const SignupScreen(),
          ),
          transitionDuration: const Duration(milliseconds: 320),
          transitionsBuilder: (_, animation, _, child) => SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          ),
        ),
      ),
      // ── Main app: a ShellRoute persists the side rail (web) / bottom nav
      // (mobile) around every URL inside. Detail screens render INTO the
      // shell's content area so the sidebar stays visible. ──
      ShellRoute(
        builder: (context, state, child) => MainShellHost(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const HomeShellPage(),
              transitionDuration: const Duration(milliseconds: 250),
              transitionsBuilder: (_, anim, _, child) =>
                  FadeTransition(opacity: anim, child: child),
            ),
          ),
          GoRoute(
            path: '/t/:taskId',
            pageBuilder: (context, state) {
              final taskId = state.pathParameters['taskId']!;
              return CustomTransitionPage(
                key: state.pageKey,
                child: TaskDetailScreen(taskId: taskId),
                transitionDuration: const Duration(milliseconds: 280),
                transitionsBuilder: _slideUp,
              );
            },
          ),
          GoRoute(
            path: '/w/:workspaceId',
            pageBuilder: (context, state) {
              final workspaceId = state.pathParameters['workspaceId']!;
              final sprint = state.uri.queryParameters['sprint'];
              return CustomTransitionPage(
                key: state.pageKey,
                child: ProjectDetailScreen(
                  projectId: workspaceId,
                  initialSprintId: sprint,
                ),
                transitionDuration: const Duration(milliseconds: 280),
                transitionsBuilder: _slideUp,
              );
            },
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ProfileScreen(),
              transitionDuration: const Duration(milliseconds: 280),
              transitionsBuilder: _slideUp,
            ),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const SearchScreen(),
              transitionDuration: const Duration(milliseconds: 180),
              transitionsBuilder: (_, anim, _, child) =>
                  FadeTransition(opacity: anim, child: child),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Route not found: ${state.uri}'))),
  );
}
