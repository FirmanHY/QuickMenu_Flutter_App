import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import '../../data/models/meal_plan_model.dart';

class DailyMenuCard extends StatelessWidget {
  final String dayName;
  final DailyMealPlanModel? plan;
  final VoidCallback onPressWeeklyPlan;

  const DailyMenuCard({
    super.key,
    required this.dayName,
    required this.plan,
    required this.onPressWeeklyPlan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title ─────────────────────────────────────────────
          Text('Menu Hari ini ($dayName)', style: AppTextStyles.h4),
          const SizedBox(height: AppDimensions.lg),

          // ── Meal rows ─────────────────────────────────────────
          _MealRow(label: 'Pagi', value: plan?.breakfast?.title),
          const SizedBox(height: AppDimensions.sm),
          _MealRow(label: 'Siang', value: plan?.lunch?.title),
          const SizedBox(height: AppDimensions.sm),
          _MealRow(label: 'Malam', value: plan?.dinner?.title),

          const SizedBox(height: AppDimensions.xl),

          // ── Button ────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: AppDimensions.buttonHeight,
            child: ElevatedButton(
              onPressed: onPressWeeklyPlan,
              child: const Text('Lihat Rencana Mingguan'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  final String label;
  final String? value;

  const _MealRow({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray600),
          ),
        ),
        Text(
          ' : ',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray600),
        ),
        Expanded(
          child: Text(
            hasValue ? value! : '-',
            style: AppTextStyles.bodyMedium.copyWith(
              color: hasValue ? AppColors.primary : AppColors.gray400,
              fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
