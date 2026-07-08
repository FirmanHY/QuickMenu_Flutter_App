// Bottom sheet "Tambah Resep" — 3 opsi setara (Import URL / Smart Paste /
// Manual), masing-masing dengan ikon + deskripsi singkat. Dipakai di
// CollectionScreen (FAB) dan HomeScreen (CTA empty state "Resep Terbaru").

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';

class AddRecipeOptionsSheet extends StatelessWidget {
  final VoidCallback onAddManual;
  final VoidCallback onImportLink;
  final VoidCallback onSmartPaste;
  final VoidCallback onCancel;

  const AddRecipeOptionsSheet({
    super.key,
    required this.onAddManual,
    required this.onImportLink,
    required this.onSmartPaste,
    required this.onCancel,
  });

  /// Tampilkan sheet secara modal.
  static Future<void> show({
    required BuildContext context,
    required VoidCallback onAddManual,
    required VoidCallback onImportLink,
    required VoidCallback onSmartPaste,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AddRecipeOptionsSheet(
        onAddManual: onAddManual,
        onImportLink: onImportLink,
        onSmartPaste: onSmartPaste,
        onCancel: () => Navigator.pop(ctx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.screenHorizontal,
        AppDimensions.lg,
        AppDimensions.screenHorizontal,
        MediaQuery.of(context).viewInsets.bottom + AppDimensions.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.gray200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppDimensions.xl),
          Text(AppStrings.addRecipe, style: AppTextStyles.h3),
          const SizedBox(height: AppDimensions.sm),
          Text(
            'Pilih cara menambahkan resep baru',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray600),
          ),
          const SizedBox(height: AppDimensions.xxl),
          _SheetOptionButton(
            icon: Icons.link_rounded,
            label: AppStrings.importFromLink,
            description: 'Tempel link resep, kami ambil detailnya otomatis',
            onTap: onImportLink,
          ),
          const SizedBox(height: AppDimensions.md),
          _SheetOptionButton(
            icon: Icons.auto_awesome_rounded,
            label: AppStrings.smartPaste,
            description:
                'Dari Instagram/TikTok? Tempel caption-nya, kami bantu deteksi',
            onTap: onSmartPaste,
          ),
          const SizedBox(height: AppDimensions.md),
          _SheetOptionButton(
            icon: Icons.edit_outlined,
            label: AppStrings.addManual,
            description: 'Tulis sendiri bahan dan langkah resepmu',
            onTap: onAddManual,
          ),
          const SizedBox(height: AppDimensions.xl),
          SizedBox(
            width: double.infinity,
            height: AppDimensions.buttonHeight,
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.gray100),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
              ),
              child: Text(
                AppStrings.cancel,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.gray600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  const _SheetOptionButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.sm),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: AppDimensions.iconXl,
              ),
            ),
            const SizedBox(width: AppDimensions.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }
}
