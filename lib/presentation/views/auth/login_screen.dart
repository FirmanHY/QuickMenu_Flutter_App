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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _showPassword  = false;

  final _errors = <String, String?>{
    'email': null,
    'password': null,
  };

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    String? emailErr, passErr;

    if (_emailCtrl.text.trim().isEmpty) {
      emailErr = 'Email wajib diisi';
    } else if (!emailRegex.hasMatch(_emailCtrl.text.trim())) {
      emailErr = 'Format email salah';
    }

    if (_passwordCtrl.text.isEmpty) {
      passErr = 'Password wajib diisi';
    }

    setState(() {
      _errors['email']    = emailErr;
      _errors['password'] = passErr;
    });

    return emailErr == null && passErr == null;
  }

  Future<void> _handleLogin() async {
    if (!_validate()) return;

    final success = await ref.read(authViewModelProvider.notifier).login(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
        );

    if (!mounted) return;
    if (success) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    // Tampilkan error dari Firebase via SnackBar
    ref.listen(authViewModelProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
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

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: KeyboardDismissOnTap(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenHorizontal,
            ),
            child: Column(
              children: [
                const SizedBox(height: 100),

                // ── Header ───────────────────────────────────────
                Column(
                  children: [
                    Text('Selamat Datang !', style: AppTextStyles.h2),
                    const SizedBox(height: 8),
                    Text(
                      'Login untuk melanjutkan ke koleksi resep Anda.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.gray600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // ── Form ─────────────────────────────────────────
                AppInput(
                  label: 'Email',
                  placeholder: 'Masukkan Email',
                  prefixIcon: Icons.email_outlined,
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  errorText: _errors['email'],
                  onChanged: (_) {
                    if (_errors['email'] != null) {
                      setState(() => _errors['email'] = null);
                    }
                  },
                ),

                AppInput(
                  label: 'Password',
                  placeholder: 'Masukkan Password',
                  prefixIcon: Icons.lock_outline,
                  controller: _passwordCtrl,
                  obscureText: !_showPassword,
                  suffixIcon: _showPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  onSuffixTap: () =>
                      setState(() => _showPassword = !_showPassword),
                  textInputAction: TextInputAction.done,
                  errorText: _errors['password'],
                  onChanged: (_) {
                    if (_errors['password'] != null) {
                      setState(() => _errors['password'] = null);
                    }
                  },
                ),

                // Lupa password
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      // TODO: forgot password
                    },
                    child: Text(
                      'Lupa Password?',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                AppButton(
                  title: 'Login',
                  onPressed: _handleLogin,
                  isLoading: authState.isLoading,
                ),

                const SizedBox(height: 60),

                // ── Footer ───────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Belum punya akun? ',
                      style: AppTextStyles.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.register),
                      child: Text(
                        'Daftar Gratis',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper widget: tap di luar keyboard dismiss
class KeyboardDismissOnTap extends StatelessWidget {
  final Widget child;
  const KeyboardDismissOnTap({super.key, required this.child});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: child,
      );
}