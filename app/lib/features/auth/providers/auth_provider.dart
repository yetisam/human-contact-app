import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user.dart';
import '../services/auth_service.dart';

/// Auth state
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
  });

  AuthState copyWith({AuthStatus? status, User? user, String? error}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
}

/// Auth state notifier using modern Riverpod Notifier
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  AuthService get _authService => ref.read(authServiceProvider);

  /// Check for existing session on app start
  Future<void> checkSession() async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final hasSession = await _authService.hasStoredSession();
      if (hasSession) {
        final user = await _authService.getProfile();
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Register new user
  Future<void> register({
    required String email,
    required String password,
    required String firstName,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);

    try {
      final user = await _authService.register(
        email: email,
        password: password,
        firstName: firstName,
      );
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = AuthState(status: AuthStatus.error, error: e.toString());
      rethrow;
    }
  }

  /// Login
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);

    try {
      // Login returns minimal user data (no interests)
      await _authService.login(
        email: email,
        password: password,
      );
      // Fetch full profile with interests for accurate isProfileComplete check
      final user = await _authService.getProfile();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = AuthState(status: AuthStatus.error, error: e.toString());
      rethrow;
    }
  }

  /// Refresh user profile data
  Future<void> refreshProfile() async {
    try {
      final user = await _authService.getProfile();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      // Keep existing state
    }
  }

  /// Logout
  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

/// Provider
final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
