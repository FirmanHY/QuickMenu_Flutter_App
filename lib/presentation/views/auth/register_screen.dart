import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/app_router.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../../viewmodels/auth_viewmodel.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;

  final _errors = <String, String?>{
    'name': null,
    'email': null,
    'password': null,
    'confirmPassword': null,
  };

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    final nameRegex = RegExp(r'^[a-zA-Z\s]{3,}$');
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

    String? nameErr, emailErr, passErr, confirmErr;

    if (_nameCtrl.text.trim().isEmpty) {
      nameErr = 'Nama wajib diisi';
    } else if (!nameRegex.hasMatch(_nameCtrl.text.trim())) {
      nameErr = 'Min 3 huruf, tanpa angka/simbol';
    }

    if (_emailCtrl.text.trim().isEmpty) {
      emailErr = 'Email wajib diisi';
    } else if (!emailRegex.hasMatch(_emailCtrl.text.trim())) {
      emailErr = 'Format email salah';
    }

    if (_passwordCtrl.text.isEmpty) {
      passErr = 'Password wajib diisi';
    } else if (_passwordCtrl.text.length < 8) {
      passErr = 'Min 8 karakter';
    }

    if (_confirmPasswordCtrl.text.isEmpty) {
      confirmErr = 'Konfirmasi password wajib';
    } else if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
      confirmErr = 'Password tidak sama';
    }

    setState(() {
      _errors['name'] = nameErr;
      _errors['email'] = emailErr;
      _errors['password'] = passErr;
      _errors['confirmPassword'] = confirmErr;
    });

    return nameErr == null &&
        emailErr == null &&
        passErr == null &&
        confirmErr == null;
  }

  Future<void> _handleRegister() async {
    if (!_validate()) return;

    await ref
        .read(authViewModelProvider.notifier)
        .register(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
          _nameCtrl.text.trim(),
        );
    // Sukses/gagal ditangani lewat authState.registrationSuccess &
    // ref.listen di build() — bukan lagi lewat return value di sini.
  }

  void _goToLogin() {
    ref.read(authViewModelProvider.notifier).dismissRegistrationSuccess();
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    ref.listen(authViewModelProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
        ref.read(authViewModelProvider.notifier).clearError();
      }
    });

    if (authState.registrationSuccess) {
      return _VerifyEmailPendingView(
        email: authState.pendingVerificationEmail ?? _emailCtrl.text.trim(),
        onContinue: _goToLogin,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenHorizontal,
            ),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // ── Header ─────────────────────────────────────
                Column(
                  children: [
                    Text('Buat Akun Baru', style: AppTextStyles.h2),
                    const SizedBox(height: 8),
                    Text(
                      'Daftar untuk mulai kelola resep favoritmu.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.gray600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── Form ───────────────────────────────────────
                AppInput(
                  label: 'Nama Lengkap',
                  placeholder: 'Masukkan Nama Lengkap',
                  prefixIcon: Icons.person_outline,
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  errorText: _errors['name'],
                  onChanged: (_) {
                    if (_errors['name'] != null) {
                      setState(() => _errors['name'] = null);
                    }
                  },
                ),

                AppInput(
                  label: 'Email',
                  placeholder: 'Masukkan Email',
                  prefixIcon: Icons.email_outlined,
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  errorText: _errors['email'],
                  onChanged: (_) {
                    if (_errors['email'] != null) {
                      setState(() => _errors['email'] = null);
                    }
                  },
                ),

                AppInput(
                  label: 'Password',
                  placeholder: 'Min. 8 karakter',
                  prefixIcon: Icons.lock_outline,
                  controller: _passwordCtrl,
                  obscureText: !_showPassword,
                  suffixIcon: _showPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  onSuffixTap: () =>
                      setState(() => _showPassword = !_showPassword),
                  textInputAction: TextInputAction.next,
                  errorText: _errors['password'],
                  onChanged: (_) {
                    if (_errors['password'] != null) {
                      setState(() => _errors['password'] = null);
                    }
                  },
                ),

                AppInput(
                  label: 'Konfirmasi Password',
                  placeholder: 'Ulangi Password',
                  prefixIcon: Icons.lock_outline,
                  controller: _confirmPasswordCtrl,
                  obscureText: !_showConfirmPassword,
                  suffixIcon: _showConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  onSuffixTap: () => setState(
                    () => _showConfirmPassword = !_showConfirmPassword,
                  ),
                  textInputAction: TextInputAction.done,
                  errorText: _errors['confirmPassword'],
                  onChanged: (_) {
                    if (_errors['confirmPassword'] != null) {
                      setState(() => _errors['confirmPassword'] = null);
                    }
                  },
                ),

                const SizedBox(height: 8),

                AppButton(
                  title: 'Daftar',
                  onPressed: _handleRegister,
                  isLoading: authState.isLoading,
                ),

                const SizedBox(height: 24),

                // ── Footer ─────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Sudah punya akun? ', style: AppTextStyles.bodyMedium),
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.login),
                      child: Text(
                        'Masuk disini',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Halaman transisi "Cek Email Kamu" — tampil penuh setelah registrasi
// berhasil, tidak bisa di-skip lewat gesture back. User wajib menekan
// tombol untuk lanjut ke Login.
// ─────────────────────────────────────────────────────────────────────────────
class _VerifyEmailPendingView extends StatelessWidget {
  final String email;
  final VoidCallback onContinue;

  const _VerifyEmailPendingView({
    required this.email,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenHorizontal,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Cek Email Kamu',
                  style: AppTextStyles.h2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Kami udah kirim link verifikasi ke',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.gray600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Klik link itu buat aktifin akun kamu sebelum login.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.gray600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                AppButton(title: 'Ke Halaman Login', onPressed: onContinue),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
