//
// Input widget reusable.
// Dipakai di: LoginScreen, RegisterScreen, AddRecipeManualScreen,
//             ExploreScreen, CollectionScreen (mode search).
//

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';

class AppInput extends StatefulWidget {
  final String? label;
  final String? placeholder;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool obscureText;
  final TextEditingController? controller;
  final String? errorText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  /// Tampilkan tombol clear (×) di kanan saat field tidak kosong.
  /// Cocok untuk use case search bar. Default false.
  final bool showClearButton;

  /// Jarak vertikal di bawah input (default: AppDimensions.lg = 16).
  /// Set ke 0 agar tidak ada margin bawah (misal saat layout parent sudah pakai SizedBox).
  final double bottomSpacing;

  const AppInput({
    super.key,
    this.label,
    this.placeholder,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false,
    this.controller,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.enabled = true,
    this.showClearButton = false,
    this.bottomSpacing = AppDimensions.lg,
  });

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  bool _isFocused = false;

  Color get _borderColor {
    if (widget.errorText != null) return AppColors.error;
    if (_isFocused) return AppColors.primary;
    return AppColors.inputBorder;
  }

  void _handleClear() {
    widget.controller?.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Label ────────────────────────────────────────────────
        if (widget.label != null) ...[
          Text(widget.label!, style: AppTextStyles.labelMedium),
          const SizedBox(height: 6),
        ],

        // ── Input container ───────────────────────────────────────
        Focus(
          onFocusChange: (focused) => setState(() => _isFocused = focused),
          child: Container(
            height: AppDimensions.inputHeight,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: _borderColor,
                width: _isFocused ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                // ── Prefix icon ─────────────────────────────────
                if (widget.prefixIcon != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: Icon(
                      widget.prefixIcon,
                      size: 20,
                      color: _isFocused ? AppColors.primary : AppColors.gray400,
                    ),
                  ),

                // ── Text field ──────────────────────────────────
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    obscureText: widget.obscureText,
                    keyboardType: widget.keyboardType,
                    textInputAction: widget.textInputAction,
                    onChanged: widget.onChanged,
                    enabled: widget.enabled,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.placeholder,
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.gray400,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 0,
                      ),
                      isDense: true,
                    ),
                  ),
                ),

                // ── Clear button (search mode) ───────────────────
                // Muncul hanya saat showClearButton=true dan ada isi.
                // Menggunakan ValueListenableBuilder agar rebuild minimal.
                if (widget.showClearButton && widget.controller != null)
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: widget.controller!,
                    builder: (_, val, _) => val.text.isNotEmpty
                        ? GestureDetector(
                            onTap: _handleClear,
                            child: const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Icon(
                                Icons.close_rounded,
                                size: AppDimensions.iconMd,
                                color: AppColors.gray400,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                // ── Suffix icon (password toggle, dsb) ───────────
                // Hanya tampil jika showClearButton=false
                if (!widget.showClearButton && widget.suffixIcon != null)
                  GestureDetector(
                    onTap: widget.onSuffixTap,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: Icon(
                        widget.suffixIcon,
                        size: 20,
                        color: AppColors.gray400,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ── Error text ────────────────────────────────────────────
        if (widget.errorText != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              widget.errorText!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],

        // ── Bottom spacing ────────────────────────────────────────
        if (widget.bottomSpacing > 0) SizedBox(height: widget.bottomSpacing),
      ],
    );
  }
}
