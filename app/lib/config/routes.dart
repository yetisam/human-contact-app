import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/onboarding/screens/welcome_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/profile/screens/profile_setup_screen.dart';
import '../features/discovery/screens/home_screen.dart';
import '../features/verification/screens/email_verification_screen.dart';
import '../features/verification/screens/phone_verification_screen.dart';
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
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: Routes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.emailVerify,
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      GoRoute(
        path: Routes.phoneVerify,
        builder: (context, state) => const PhoneVerificationScreen(),
      ),
      GoRoute(
        path: Routes.profileSetup,
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: Routes.chatDetail,
        builder: (context, state) {
          final connectionId = state.pathParameters['connectionId']!;
          return ChatScreen(connectionId: connectionId);
        },
      ),
      GoRoute(
        path: Routes.exchange,
        builder: (context, state) {
          final connectionId = state.pathParameters['connectionId']!;
          return ExchangeScreen(connectionId: connectionId);
        },
      ),
    ],
  );
}

/// Provider for the router
final appRouterProvider = Provider<GoRouter>((ref) {
  return createAppRouter(ref);
});
