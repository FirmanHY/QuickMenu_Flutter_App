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
  final bool isEmailNotVerifiedError;
  final bool
  registrationSuccess; // trigger halaman "cek email" di Register screen
  final String? pendingVerificationEmail;

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.isEmailNotVerifiedError = false,
    this.registrationSuccess = false,
    this.pendingVerificationEmail,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool isEmailNotVerifiedError = false,
    bool? registrationSuccess,
    String? pendingVerificationEmail,
  }) => AuthState(
    isLoading: isLoading ?? this.isLoading,
    errorMessage: errorMessage, // null = clear error
    isEmailNotVerifiedError: isEmailNotVerifiedError,
    registrationSuccess: registrationSuccess ?? this.registrationSuccess,
    pendingVerificationEmail:
        pendingVerificationEmail ?? this.pendingVerificationEmail,
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
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        isEmailNotVerifiedError: e is EmailNotVerifiedException,
      );
      return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      registrationSuccess: false,
    );
    try {
      await _repo.registerWithEmail(email.trim(), password, name.trim());
      state = state.copyWith(
        isLoading: false,
        registrationSuccess: true,
        pendingVerificationEmail: email.trim(),
      );
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

  void clearError() => state = state.copyWith(
    errorMessage: null,
    isEmailNotVerifiedError: false,
  );

  void dismissRegistrationSuccess() =>
      state = state.copyWith(registrationSuccess: false);
}

final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(
  AuthViewModel.new,
);
