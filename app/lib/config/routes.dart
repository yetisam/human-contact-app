import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/onboarding/screens/welcome_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/profile/screens/profile_setup_screen.dart';
import '../features/discovery/screens/home_screen.dart';
import '../features/verification/screens/email_verification_screen.dart';
import '../features/verification/screens/phone_verification_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/chat/screens/chat_screen.dart';
import '../features/exchange/screens/exchange_screen.dart';

/// App route paths
class Routes {
  Routes._();

  // Onboarding
  static const String welcome = '/';
  static const String login = '/login';
  static const String register = '/register';

  // Verification
  static const String emailVerify = '/verify/email';
  static const String phoneVerify = '/verify/phone';
  static const String idVerify = '/verify/id';

  // Profile
  static const String profileSetup = '/profile/setup';
  static const String profileEdit = '/profile/edit';

  // Main app
  static const String home = '/home';
  static const String matches = '/matches';
  static const String connections = '/connections';
  static const String chat = '/chat';
  static const String chatDetail = '/chat/:connectionId';
  static const String myConnections = '/my-connections';

  // Contact exchange
  static const String exchange = '/exchange/:connectionId';

  // Safety
  static const String safetyCenter = '/safety';

  // Settings
  static const String settings = '/settings';
}

/// Determine the correct destination for an authenticated user
/// based on their verification and profile state
String _getAuthenticatedRoute(dynamic user) {
  if (user == null) return Routes.home;

  // Step 1: Email verification
  if (!user.emailVerified) return Routes.emailVerify;

  // Step 2: Phone verification
  if (!user.phoneVerified) return Routes.phoneVerify;

  // Step 3: Profile setup
  if (!user.isProfileComplete) return Routes.profileSetup;

  // All done — go home
  return Routes.home;
}

/// App router configuration
GoRouter createAppRouter(Ref ref) {
  return GoRouter(
    initialLocation: Routes.welcome,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final isAuth = auth.isAuthenticated;
      final currentPath = state.matchedLocation;
      final isAuthRoute = currentPath == Routes.welcome ||
          currentPath == Routes.login ||
          currentPath == Routes.register;

      // Not authenticated — only allow auth routes
      if (!isAuth) {
        if (isAuthRoute) return null; // Stay on auth pages
        return Routes.welcome; // Redirect to welcome
      }

      // Authenticated — redirect away from auth pages
      if (isAuthRoute) {
        return _getAuthenticatedRoute(auth.user);
      }

      // Authenticated — ensure they're on the right step
      final user = auth.user;
      if (user != null) {
        final correctRoute = _getAuthenticatedRoute(user);
        final isOnboardingRoute = currentPath == Routes.emailVerify ||
            currentPath == Routes.phoneVerify ||
            currentPath == Routes.profileSetup;

        // If they're on an onboarding route but should be somewhere else, redirect
        if (isOnboardingRoute && currentPath != correctRoute) {
          // Allow going forward but not backward in onboarding
          // If correctRoute is home, they're done — let them go
          if (correctRoute == Routes.home) return Routes.home;
          // Otherwise redirect to the correct step
          return correctRoute;
        }
      }

      return null; // No redirect
    },
    routes: [
      GoRoute(
        path: Routes.welcome,
        pageBuilder: (context, state) => _buildFadePage(
          key: state.pageKey,
          child: const WelcomeScreen(),
        ),
      ),
      GoRoute(
        path: Routes.register,
        pageBuilder: (context, state) => _buildSlidePage(
          key: state.pageKey,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: Routes.login,
        pageBuilder: (context, state) => _buildSlidePage(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: Routes.emailVerify,
        pageBuilder: (context, state) => _buildSlidePage(
          key: state.pageKey,
          child: const EmailVerificationScreen(),
        ),
      ),
      GoRoute(
        path: Routes.phoneVerify,
        pageBuilder: (context, state) => _buildSlidePage(
          key: state.pageKey,
          child: const PhoneVerificationScreen(),
        ),
      ),
      GoRoute(
        path: Routes.profileSetup,
        pageBuilder: (context, state) => _buildSlidePage(
          key: state.pageKey,
          child: const ProfileSetupScreen(),
        ),
      ),
      GoRoute(
        path: Routes.home,
        pageBuilder: (context, state) => _buildFadePage(
          key: state.pageKey,
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: Routes.chatDetail,
        pageBuilder: (context, state) {
          final connectionId = state.pathParameters['connectionId']!;
          return _buildSlidePage(
            key: state.pageKey,
            child: ChatScreen(connectionId: connectionId),
          );
        },
      ),
      GoRoute(
        path: Routes.exchange,
        pageBuilder: (context, state) {
          final connectionId = state.pathParameters['connectionId']!;
          return _buildSlidePage(
            key: state.pageKey,
            child: ExchangeScreen(connectionId: connectionId),
          );
        },
      ),
      GoRoute(
        path: Routes.settings,
        pageBuilder: (context, state) => _buildSlidePage(
          key: state.pageKey,
          child: const SettingsScreen(),
        ),
      ),
    ],
  );
}

/// Page transition builders
Page<void> _buildSlidePage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOut;

      var tween = Tween(begin: begin, end: end).chain(
        CurveTween(curve: curve),
      );

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}

Page<void> _buildFadePage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: child,
      );
    },
  );
}

/// Provider for the router
final appRouterProvider = Provider<GoRouter>((ref) {
  return createAppRouter(ref);
});
