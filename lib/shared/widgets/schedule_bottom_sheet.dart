// Bottom sheet untuk menjadwalkan resep ke meal plan.
// Menampilkan: date picker (tanggal dari hari ini ke depan) + pilihan slot (sarapan/siang/malam).
// Setara dengan ScheduleRecipeSheetContent di React Native.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/models/meal_plan_model.dart';
import '../widgets/app_button.dart';

class ScheduleBottomSheet extends StatefulWidget {
  final Future<void> Function(DateTime date, MealType mealType) onSave;
  final bool isSaving;

  const ScheduleBottomSheet({
    super.key,
    required this.onSave,
    this.isSaving = false,
  });

  /// Tampilkan sheet secara modal dan kembalikan true jika berhasil disimpan.
  static Future<void> show({
    required BuildContext context,
    required Future<void> Function(DateTime date, MealType mealType) onSave,
    bool isSaving = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScheduleBottomSheet(onSave: onSave, isSaving: isSaving),
    );
  }

  @override
  State<ScheduleBottomSheet> createState() => _ScheduleBottomSheetState();
}

class _ScheduleBottomSheetState extends State<ScheduleBottomSheet> {
  late DateTime _selectedDate;
  MealType _selectedMeal = MealType.breakfast;
  bool _isSaving = false;

  // Rentang tanggal yang bisa dipilih: hari ini s.d. 30 hari ke depan
  late final DateTime _firstDate;
  late final DateTime _lastDate;

  static const _mealOptions = [
    (type: MealType.breakfast, label: 'Sarapan', icon: Icons.wb_sunny_rounded),
    (type: MealType.lunch, label: 'Makan Siang', icon: Icons.lunch_dining),
    (
      type: MealType.dinner,
      label: 'Makan Malam',
      icon: Icons.nights_stay_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _firstDate = DateTime(now.year, now.month, now.day);
    _lastDate = _firstDate.add(const Duration(days: 30));
    _selectedDate = _firstDate;
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      await widget.onSave(_selectedDate, _selectedMeal);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: _firstDate,
      lastDate: _lastDate,
      locale: const Locale('id', 'ID'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.xxl,
        AppDimensions.lg,
        AppDimensions.xxl,
        AppDimensions.xxl + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXxl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Drag handle ─────────────────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.lg),

          // ── Title ────────────────────────────────────────────────────────
          Text('Jadwalkan Resep', style: AppTextStyles.h3),
          const SizedBox(height: AppDimensions.xs),
          Text('Pilih tanggal dan waktu makan', style: AppTextStyles.bodySmall),
          const SizedBox(height: AppDimensions.xl),

          // ── Date Picker ───────────────────────────────────────────────────
          Text('Tanggal', style: AppTextStyles.labelMedium),
          const SizedBox(height: AppDimensions.sm),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.lg,
                vertical: AppDimensions.md,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.inputBorder),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                color: AppColors.white,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: AppDimensions.iconMd,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Text(
                    DateFormat(
                      'EEEE, d MMMM yyyy',
                      'id_ID',
                    ).format(_selectedDate),
                    style: AppTextStyles.bodyMedium,
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.gray400,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.xl),

          // ── Meal Slot ─────────────────────────────────────────────────────
          Text('Waktu Makan', style: AppTextStyles.labelMedium),
          const SizedBox(height: AppDimensions.sm),
          Row(
            children: _mealOptions.map((option) {
              final isSelected = _selectedMeal == option.type;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: option.type != MealType.dinner
                        ? AppDimensions.sm
                        : 0,
                  ),
                  child: _MealSlotChip(
                    label: option.label,
                    icon: option.icon,
                    isSelected: isSelected,
                    onTap: () => setState(() => _selectedMeal = option.type),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppDimensions.xxxl),

          // ── Save Button ───────────────────────────────────────────────────
          AppButton(
            title: 'Simpan Jadwal',
            onPressed: _handleSave,
            isLoading: _isSaving || widget.isSaving,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widget: Meal Slot Chip
// ─────────────────────────────────────────────────────────────────────────────

class _MealSlotChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _MealSlotChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.md,
          horizontal: AppDimensions.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.inputBorder,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: AppDimensions.iconMd,
              color: isSelected ? AppColors.white : AppColors.gray400,
            ),
            const SizedBox(height: AppDimensions.xs),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? AppColors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
