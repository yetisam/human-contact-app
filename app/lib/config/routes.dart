import 'package:go_router/go_router.dart';
import '../features/onboarding/screens/welcome_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/login_screen.dart';

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
final GoRouter appRouter = GoRouter(
  initialLocation: Routes.welcome,
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
    // More routes will be added as screens are built
  ],
);
