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

/// App router configuration
GoRouter createAppRouter(Ref ref) {
  return GoRouter(
    initialLocation: Routes.welcome,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final isAuth = auth.isAuthenticated;
      final isAuthRoute = state.matchedLocation == Routes.welcome ||
          state.matchedLocation == Routes.login ||
          state.matchedLocation == Routes.register;

      // If authenticated and on auth page, redirect to home or profile setup
      if (isAuth && isAuthRoute) {
        final user = auth.user;
        if (user != null && !user.isProfileComplete) {
          return Routes.profileSetup;
        }
        return Routes.home;
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
