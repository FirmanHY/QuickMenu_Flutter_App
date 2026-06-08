import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  static const String _font = 'NunitoSans';

  // Heading
  static const TextStyle h1 = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w700,
    fontSize: 24,
    color: AppColors.textPrimary,
  );
  static const TextStyle h2 = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w700,
    fontSize: 20,
    color: AppColors.textPrimary,
  );
  static const TextStyle h3 = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w700,
    fontSize: 18,
    color: AppColors.textPrimary,
  );
  static const TextStyle h4 = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  static const TextStyle bodySmall = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // Label
  static const TextStyle labelLarge = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: AppColors.textPrimary,
  );
  static const TextStyle labelMedium = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    color: AppColors.textPrimary,
  );
  static const TextStyle labelSmall = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w600,
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  // Button
  static const TextStyle button = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    letterSpacing: 0.2,
  );

  // Caption
  static const TextStyle caption = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w400,
    fontSize: 11,
    color: AppColors.textSecondary,
  );
}
