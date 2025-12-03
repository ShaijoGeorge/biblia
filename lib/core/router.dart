import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'widgets/main_wrapper.dart';
import '../data/bible_data.dart';
import '../features/home/screens/home_screen.dart';
import '../features/reading/screens/old_testament_screen.dart';
import '../features/reading/screens/new_testament_screen.dart';
import '../features/reading/screens/chapters_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/update_password_screen.dart';
import '../features/auth/screens/profile_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import 'widgets/not_found_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Listen to the Supabase Auth Stream directly
  final authStream = Supabase.instance.client.auth.onAuthStateChange;

  // FIX 1 (Continued): Create the key INSIDE the provider.
  // This ensures a fresh key is generated whenever the Router is rebuilt.
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/home',
    
    // Refresh the router whenever Auth State changes (Login, Logout, Recovery)
    refreshListenable: GoRouterRefreshStream(authStream),

    errorBuilder: (context, state) {
      return NotFoundScreen(error: state.error);
    },

    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      
      final isLoginRoute = state.uri.toString() == '/login';
      final isForgotRoute = state.uri.toString() == '/forgot-password';
      final isUpdatePasswordRoute = state.uri.toString() == '/update-password';

      // 1. If NOT logged in...
      if (!isLoggedIn && !isLoginRoute && !isForgotRoute && !isUpdatePasswordRoute) {
        return '/login';
      }

      // 2. If LOGGED IN...
      if (isLoggedIn) {
        // If they are specifically trying to go to Login, send them Home. 
        if (isLoginRoute) {
          return '/home';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      // NEW: The screen for setting a new password
      GoRoute(
        path: '/update-password',
        builder: (context, state) => const UpdatePasswordScreen(),
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
      // Use the local 'rootNavigatorKey' for these routes to cover the tabs
      GoRoute(
        path: '/book/:bookId',
        parentNavigatorKey: rootNavigatorKey, 
        builder: (context, state) {
          final bookId = int.parse(state.pathParameters['bookId']!);
          final book = kBibleBooks.firstWhere((b) => b.id == bookId);
          return ChaptersScreen(book: book);
        },
      ),

      // Profile Route
      GoRoute(
        path: '/profile',
        parentNavigatorKey: rootNavigatorKey, 
        builder: (context, state) => const ProfileScreen(),
      ),

      // Settings Route
      GoRoute(
        path: '/settings',
        parentNavigatorKey: rootNavigatorKey, 
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});

// Helper class to make Stream listenable for GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}