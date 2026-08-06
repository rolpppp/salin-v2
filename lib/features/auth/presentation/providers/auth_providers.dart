import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/sync/sync_providers.dart';

enum AuthStatus {
  authenticated,
  unauthenticated,
  unconfirmed,
  loading,
  error,
}

class AuthState {
  final AuthStatus status;
  final String? email;
  final String? error;

  const AuthState({
    required this.status,
    this.email,
    this.error,
  });

  factory AuthState.unauthenticated() => const AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);
  factory AuthState.authenticated(String email) => AuthState(status: AuthStatus.authenticated, email: email);
  factory AuthState.unconfirmed(String email) => AuthState(status: AuthStatus.unconfirmed, email: email);
  factory AuthState.error(String message) => AuthState(status: AuthStatus.error, error: message);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(AuthState.unauthenticated()) {
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    final provider = _ref.read(cloudSyncProvider);
    final email = await provider.getCurrentUserEmail();
    if (email != null) {
      state = AuthState.authenticated(email);
    } else {
      state = AuthState.unauthenticated();
    }
  }

  Future<bool> login(String email, String password) async {
    state = AuthState.loading();
    try {
      final success = await _ref.read(cloudSyncProvider).login(email, password);
      if (success) {
        state = AuthState.authenticated(email);
        return true;
      } else {
        state = AuthState.error('Invalid email or password.');
        return false;
      }
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    state = AuthState.loading();
    try {
      final provider = _ref.read(cloudSyncProvider);
      final success = await provider.register(email, password);
      if (success) {
        final currentEmail = await provider.getCurrentUserEmail();
        if (currentEmail != null) {
          state = AuthState.authenticated(email);
        } else {
          state = AuthState.unconfirmed(email);
        }
        return true;
      } else {
        state = AuthState.error('Registration failed. Please try again.');
        return false;
      }
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    state = AuthState.loading();
    try {
      await _ref.read(cloudSyncProvider).logout();
    } catch (_) {}
    state = AuthState.unauthenticated();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
