import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import '../screens/login_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/alarms_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/chart_screen.dart';
import '../screens/users_screen.dart';
import '../screens/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
          final isLoggedIn  = authState.isLoggedIn;
          final isLoginPage = state.matchedLocation == '/login';
          final user        = authState.user;

          if (!isLoggedIn && !isLoginPage) return '/login';
          if (isLoggedIn && isLoginPage)   return '/dashboard';

          // Управление пользователями — только админ
          if (isLoggedIn &&
              user?.canManageUsers == false &&
              state.matchedLocation.startsWith('/users')) {
            return '/dashboard';
          }

          return null;
        },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            DashboardShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const MonitoringTab(),
          ),
          GoRoute(
            path: '/alarms',
            builder: (context, state) => const AlarmsScreen(),
          ),
          GoRoute(
            path: '/charts',
            builder: (context, state) => const ChartScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/users',
            builder: (context, state) => const UsersScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});