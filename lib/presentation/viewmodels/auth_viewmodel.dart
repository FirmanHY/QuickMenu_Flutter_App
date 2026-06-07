import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/app_exception.dart';
import '../../data/repositories/auth_repository.dart';

// ── Provider ──────────────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges,
);

// ── State ─────────────────────────────────────────────────────
class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final bool registrationSuccess; // untuk trigger snackbar di Register screen

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.registrationSuccess = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? registrationSuccess,
  }) =>
      AuthState(
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,           // null = clear error
        registrationSuccess: registrationSuccess ?? this.registrationSuccess,
      );
}

// ── ViewModel ─────────────────────────────────────────────────
class AuthViewModel extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repo.signInWithEmail(email.trim(), password);
      state = state.copyWith(isLoading: false);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, errorMessage: null, registrationSuccess: false);
    try {
      await _repo.registerWithEmail(email.trim(), password, name.trim());
      state = state.copyWith(isLoading: false, registrationSuccess: true);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.signOut();
    state = const AuthState();
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}

final authViewModelProvider =
    NotifierProvider<AuthViewModel, AuthState>(AuthViewModel.new);