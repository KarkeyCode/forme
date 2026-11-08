import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/diet_screen.dart';
import 'screens/health_overview_screen.dart';
import 'screens/home_shell.dart';
import 'screens/dashboard_screen.dart';
import 'screens/onboarding/customize_profile_screen.dart';
import 'screens/onboarding/health_sync_screen.dart';
import 'screens/onboarding/how_it_works_screen.dart';
import 'screens/onboarding/intro_screen.dart';
import 'screens/onboarding/loading_screen.dart';
import 'screens/onboarding/login_screen.dart';
import 'screens/onboarding/points_intro_screen.dart';
import 'screens/onboarding/profile_setup_screen.dart';
import 'screens/onboarding/reminders_screen.dart';
import 'screens/onboarding/security_screen.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'screens/pro_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/rewards_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/workout_screen.dart';
import 'services/app_state.dart';

CustomTransitionPage<void> _fade(Widget child, GoRouterState s) =>
    CustomTransitionPage(
      key: s.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
    );

CustomTransitionPage<void> _slideUp(Widget child, GoRouterState s) =>
    CustomTransitionPage(
      key: s.pageKey,
      fullscreenDialog: true,
      child: child,
      transitionsBuilder: (_, a, __, c) => SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
        child: c,
      ),
    );

GoRouter buildRouter(AppState state) => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', pageBuilder: (_, s) => _fade(const SplashScreen(), s)),
        // Onboarding flow: welcome -> intro -> how -> security -> login ->
        // customize -> sync -> profile setup -> reminders -> points intro ->
        // loading -> home.
        GoRoute(path: '/welcome', pageBuilder: (_, s) => _fade(const WelcomeScreen(), s)),
        GoRoute(path: '/intro', pageBuilder: (_, s) => _fade(const IntroScreen(), s)),
        GoRoute(path: '/how', pageBuilder: (_, s) => _fade(const HowItWorksScreen(), s)),
        GoRoute(path: '/security', pageBuilder: (_, s) => _fade(const SecurityScreen(), s)),
        GoRoute(path: '/login', pageBuilder: (_, s) => _fade(const LoginScreen(), s)),
        GoRoute(path: '/customize', pageBuilder: (_, s) => _fade(const CustomizeProfileScreen(), s)),
        GoRoute(path: '/sync', pageBuilder: (_, s) => _fade(const HealthSyncScreen(), s)),
        GoRoute(path: '/profile-setup', pageBuilder: (_, s) => _fade(const ProfileSetupScreen(), s)),
        GoRoute(path: '/reminders', pageBuilder: (_, s) => _fade(const RemindersScreen(), s)),
        GoRoute(path: '/points-intro', pageBuilder: (_, s) => _fade(const PointsIntroScreen(), s)),
        GoRoute(path: '/loading', pageBuilder: (_, s) => _fade(const LoadingScreen(), s)),
        // Modals / detail pages.
        GoRoute(path: '/pro', pageBuilder: (_, s) => _slideUp(const ProScreen(), s)),
        GoRoute(path: '/rewards', pageBuilder: (_, s) => _slideUp(const RewardsScreen(), s)),
        GoRoute(path: '/overview', pageBuilder: (_, s) => _slideUp(const HealthOverviewScreen(), s)),
        StatefulShellRoute.indexedStack(
          builder: (_, __, shell) => HomeShell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(path: '/home', builder: (_, __) => const DashboardScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/diet', builder: (_, __) => const DietScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/workout', builder: (_, __) => const WorkoutScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
            ]),
          ],
        ),
      ],
    );
