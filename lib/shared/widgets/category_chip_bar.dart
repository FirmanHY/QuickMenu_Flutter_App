import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CategoryChipBar
//
// Horizontal scrollable row of filter chips.
//
// Usage:
//   CategoryChipBar(
//     categories: ['Semua', 'Sarapan', 'Makan Siang'],
//     selected: 'Semua',
//     onSelected: (cat) => ...,
//   )
//
// Opsional — wrap dengan padding sendiri di parent, atau pakai [padding].
// ─────────────────────────────────────────────────────────────────────────────

class CategoryChipBar extends StatelessWidget {
  /// Daftar label kategori; urutan tampil sesuai urutan list.
  final List<String> categories;

  /// Kategori yang sedang aktif/terpilih.
  final String selected;

  /// Callback saat user tap salah satu chip.
  final ValueChanged<String> onSelected;

  /// Padding horizontal di luar area scroll (default 0 — atur dari parent).
  /// Berguna saat chip bar perlu "bleed" ke tepi layar.
  final EdgeInsetsGeometry? padding;

  /// Jarak antar chip (default [AppDimensions.sm] = 8).
  final double chipSpacing;

  const CategoryChipBar({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
    this.padding,
    this.chipSpacing = AppDimensions.sm,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        children: [
          for (int i = 0; i < categories.length; i++) ...[
            _CategoryChip(
              label: categories[i],
              isActive: selected == categories[i],
              onTap: () => onSelected(categories[i]),
            ),
            if (i < categories.length - 1) SizedBox(width: chipSpacing),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CategoryChip  (private — hanya dipakai oleh CategoryChipBar)
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.lg,
          vertical: AppDimensions.md,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.gray200,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            fontSize: 13,
            color: isActive ? AppColors.white : AppColors.gray600,
          ),
        ),
      ),
    );
  }
}
