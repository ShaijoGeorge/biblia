import 'package:biblia/features/auth/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/main_wrapper.dart';
import '../data/bible_data.dart';
import '../features/home/screens/home_screen.dart';
import '../features/reading/screens/old_testament_screen.dart';
import '../features/reading/screens/new_testament_screen.dart';
import '../features/reading/screens/chapters_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/profile_screen.dart';
import '../features/settings/screens/settings_screen.dart';

// 1. Create a Global Key for the Root Navigator
// This key allows us to push screens *over* the bottom navigation bar
final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authUserProvider);

  return GoRouter(
    // 2. Register the key with the Router
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.uri.toString() == '/login';

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/home';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainWrapper(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/old-testament',
                builder: (context, state) => const OldTestamentScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/new-testament',
                builder: (context, state) => const NewTestamentScreen(),
              ),
            ],
          ),
        ],
      ),
      // 3. Use the _rootNavigatorKey here
      // This tells GoRouter: "Render this screen on the Root Navigator, covering the tabs"
      GoRoute(
        path: '/book/:bookId',
        parentNavigatorKey: _rootNavigatorKey, 
        builder: (context, state) {
          final bookId = int.parse(state.pathParameters['bookId']!);
          final book = kBibleBooks.firstWhere((b) => b.id == bookId);
          return ChaptersScreen(book: book);
        },
      ),

      // Profile Route
      GoRoute(
        path: '/profile',
        parentNavigatorKey: _rootNavigatorKey, // Cover the tabs
        builder: (context, state) => const ProfileScreen(),
      ),

      // Settings Route
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey, // Cover the tabs
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});