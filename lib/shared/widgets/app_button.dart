import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';

enum AppButtonType { primary, outline }

class AppButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;
  final AppButtonType type;
  final bool isLoading;
  final bool disabled;
  final double? width;

  const AppButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.isLoading = false,
    this.disabled = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = type == AppButtonType.primary;
    final isDisabled = disabled || isLoading;

    return SizedBox(
      width: width ?? double.infinity,
      height: AppDimensions.buttonHeight,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled
              ? (isPrimary ? AppColors.gray100 : Colors.transparent)
              : (isPrimary ? AppColors.primary : Colors.transparent),
          foregroundColor: isDisabled
              ? AppColors.gray400
              : (isPrimary ? AppColors.white : AppColors.primary),
          elevation: 0,
          side: isPrimary
              ? BorderSide.none
              : BorderSide(
                  color: isDisabled ? AppColors.gray100 : AppColors.primary,
                ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: isPrimary ? AppColors.white : AppColors.primary,
                ),
              )
            : Text(title, style: AppTextStyles.button),
      ),
    );
  }
}
