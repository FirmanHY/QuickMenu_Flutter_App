// Kartu rencana makan harian — migrasi dari DailyMealCard.tsx (React Native).
// Menampilkan 3 slot (Sarapan / Makan Siang / Makan Malam).
// Setiap slot bisa berisi resep atau kosong (+ tombol tambah).

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/models/meal_plan_model.dart';

class DailyMealCard extends StatelessWidget {
  final DailyMealPlanModel day;
  final String dateDisplay;
  final void Function(MealType type) onAdd;
  final void Function(MealType type) onRemove;
  final void Function(String recipeId)? onPressMeal;

  const DailyMealCard({
    super.key,
    required this.day,
    required this.dateDisplay,
    required this.onAdd,
    required this.onRemove,
    this.onPressMeal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header tanggal ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.lg,
              vertical: AppDimensions.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.25),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimensions.radiusLg),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: AppDimensions.iconSm,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: AppDimensions.xs),
                Text(
                  dateDisplay,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),

          // ── Slot meals ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Column(
              children: [
                _MealRow(
                  type: MealType.breakfast,
                  meal: day.breakfast,
                  onAdd: () => onAdd(MealType.breakfast),
                  onRemove: () => onRemove(MealType.breakfast),
                  onPress: day.breakfast != null
                      ? () => onPressMeal?.call(day.breakfast!.recipeId)
                      : null,
                ),
                const SizedBox(height: AppDimensions.md),
                _MealRow(
                  type: MealType.lunch,
                  meal: day.lunch,
                  onAdd: () => onAdd(MealType.lunch),
                  onRemove: () => onRemove(MealType.lunch),
                  onPress: day.lunch != null
                      ? () => onPressMeal?.call(day.lunch!.recipeId)
                      : null,
                ),
                const SizedBox(height: AppDimensions.md),
                _MealRow(
                  type: MealType.dinner,
                  meal: day.dinner,
                  onAdd: () => onAdd(MealType.dinner),
                  onRemove: () => onRemove(MealType.dinner),
                  onPress: day.dinner != null
                      ? () => onPressMeal?.call(day.dinner!.recipeId)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MealRow: satu baris slot (label + isi atau tombol tambah)
// ─────────────────────────────────────────────────────────────────────────────

class _MealRow extends StatelessWidget {
  final MealType type;
  final MealItemModel? meal;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback? onPress;

  const _MealRow({
    required this.type,
    required this.meal,
    required this.onAdd,
    required this.onRemove,
    this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Label (lebar tetap) ────────────────────────────────────────
        SizedBox(
          width: 90,
          child: Text(
            '${type.label}:',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.gray600,
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.sm),

        // ── Isi slot ──────────────────────────────────────────────────
        Expanded(
          child: meal != null
              ? _FilledSlot(meal: meal!, onPress: onPress, onRemove: onRemove)
              : _EmptySlot(onAdd: onAdd),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FilledSlot: slot berisi resep — gambar + judul + tombol hapus
// ─────────────────────────────────────────────────────────────────────────────

class _FilledSlot extends StatelessWidget {
  final MealItemModel meal;
  final VoidCallback? onPress;
  final VoidCallback onRemove;

  const _FilledSlot({
    required this.meal,
    required this.onPress,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPress,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.sm),
        decoration: BoxDecoration(
          color: AppColors.lime,
          border: Border.all(color: AppColors.green),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: Row(
          children: [
            // Gambar resep
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusSm),
              child: CachedNetworkImage(
                imageUrl: meal.imageUrl?.isNotEmpty == true
                    ? meal.imageUrl!
                    : 'https://via.placeholder.com/80x80?text=No+Image',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 40,
                  height: 40,
                  color: AppColors.gray200,
                  child: const Icon(Icons.restaurant_rounded,
                      size: 20, color: AppColors.gray400),
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.sm),

            // Judul resep
            Expanded(
              child: Text(
                meal.title,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppDimensions.xs),

            // Tombol hapus
            GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EmptySlot: slot kosong — dashed border + tombol tambah
// ─────────────────────────────────────────────────────────────────────────────

class _EmptySlot extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptySlot({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: AppColors.gray100,
            // Dart tidak punya borderStyle: dashed di BoxDecoration standar,
            // gunakan CustomPainter atau DashedBorder package.
            // Untuk kesederhanaan, gunakan border solid tipis dengan warna terang.
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              size: AppDimensions.iconMd,
              color: AppColors.gray400,
            ),
            const SizedBox(width: AppDimensions.xs),
            Text(
              'Tambah',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.gray400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}