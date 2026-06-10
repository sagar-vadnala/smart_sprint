import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_sprint/core/auth/auth_session.dart';
import 'package:smart_sprint/features/auth/bloc/auth_bloc.dart';
import 'package:smart_sprint/features/auth/view/login_screen.dart';
import 'package:smart_sprint/features/auth/view/signup_screen.dart';
import 'package:smart_sprint/features/landing/view/landing_screen.dart';
import 'package:smart_sprint/features/landing/view/pages/features_page.dart';
import 'package:smart_sprint/features/landing/view/pages/pricing_page.dart';
import 'package:smart_sprint/features/landing/view/pages/sprints_page.dart';
import 'package:smart_sprint/features/landing/view/pages/teams_page.dart';
import 'package:smart_sprint/features/invite/view/accept_invite_screen.dart';
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

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

abstract final class AppRouter {
  // Routes that require a signed-in user. Everything else (landing, login,
  // signup, splash, onboarding, invite links) is public.
  static bool _isProtected(String location) {
    const exact = {'/home', '/profile', '/search'};
    return exact.contains(location) ||
        location.startsWith('/t/') ||
        location.startsWith('/w/');
  }

  // Screens that only make sense when signed OUT — a signed-in user hitting
  // these is sent into the app.
  static bool _isAuthScreen(String location) =>
      location == '/login' || location == '/signup';

  static final router = GoRouter(
    // Web opens on the public marketing landing page (no mobile-style splash);
    // native apps keep the animated splash → onboarding/login flow.
    initialLocation: kIsWeb ? '/' : '/splash',
    // Re-run redirects the instant auth changes (login, logout, or a 401
    // clearing the token), so the guards below always reflect reality.
    refreshListenable: authSession,
    // ── Centralised auth guard (single source of truth: AuthSession) ──
    // Synchronous, so it never races with in-flight data loading.
    redirect: (context, state) {
      final signedIn = authSession.isSignedIn;
      final loc = state.matchedLocation;

      // Not signed in → can't touch app routes. Remember where they were
      // headed so we can return them there after login (e.g. an invite link).
      if (_isProtected(loc) && !signedIn) {
        final dest = state.uri.toString();
        return '/login?next=${Uri.encodeComponent(dest)}';
      }

      // Already signed in → bounce away from login/signup. Honour a pending
      // ?next= deep link if present (and safe), otherwise go home.
      if (_isAuthScreen(loc) && signedIn) {
        final next = state.uri.queryParameters['next'];
        if (next != null &&
            next.isNotEmpty &&
            !next.startsWith('/login') &&
            !next.startsWith('/signup')) {
          return next;
        }
        return '/home';
      }

      return null;
    },
    routes: [
      // Public web landing page. Standalone (no app shell); forwards
      // already-signed-in visitors to /home itself.
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LandingScreen(),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      // Public marketing sub-pages (web). Standalone, share the landing chrome.
      GoRoute(
        path: '/features',
        pageBuilder: (context, state) => _fadePage(state, const FeaturesPage()),
      ),
      GoRoute(
        path: '/sprints',
        pageBuilder: (context, state) => _fadePage(state, const SprintsPage()),
      ),
      GoRoute(
        path: '/teams',
        pageBuilder: (context, state) => _fadePage(state, const TeamsPage()),
      ),
      GoRoute(
        path: '/pricing',
        pageBuilder: (context, state) => _fadePage(state, const PricingPage()),
      ),
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
      // Invitation accept link (emailed to invitees). Standalone — no app shell;
      // routes the visitor to login/signup and back if they're not signed in.
      GoRoute(
        path: '/invite/:token',
        pageBuilder: (context, state) => _fadePage(
          state,
          AcceptInviteScreen(token: state.pathParameters['token']!),
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
