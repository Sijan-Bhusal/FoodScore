import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../data/auth_data_source.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error, guest }

class AuthState {
  final AuthStatus status;
  final UserProfile? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserProfile? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(client: ref.read(httpClientProvider));
});

final authDataSourceProvider = Provider<AuthDataSource>((ref) {
  return AuthDataSource(client: ref.read(httpClientProvider));
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(dataSource: ref.read(authDataSourceProvider));
});

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState();
  }

  Future<void> checkAuth() async {
    final apiClient = ref.read(apiClientProvider);
    final token = await apiClient.accessToken;
    if (token == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      final dataSource = ref.read(authDataSourceProvider);
      final userData = await dataSource.getMe(token);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: UserProfile.fromJson(userData),
      );
    } catch (_) {
      await apiClient.clearTokens();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  void skipToApp() {
    state = const AuthState(status: AuthStatus.guest);
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final authService = ref.read(authServiceProvider);
      final apiClient = ref.read(apiClientProvider);
      final result = await authService.signInWithGoogle();
      await apiClient.saveTokens(result.accessToken, result.refreshToken);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.user,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final authService = ref.read(authServiceProvider);
      final apiClient = ref.read(apiClientProvider);
      final result = await authService.signInWithEmail(email, password);
      await apiClient.saveTokens(result.accessToken, result.refreshToken);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.user,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> register(String username, String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final authService = ref.read(authServiceProvider);
      final apiClient = ref.read(apiClientProvider);
      final result = await authService.register(username, email, password);
      await apiClient.saveTokens(result.accessToken, result.refreshToken);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.user,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    final authService = ref.read(authServiceProvider);
    final apiClient = ref.read(apiClientProvider);
    await authService.signOut();
    await apiClient.clearTokens();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
