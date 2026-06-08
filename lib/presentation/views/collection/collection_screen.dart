import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/app_router.dart';
import '../../../presentation/viewmodels/recipe_viewmodel.dart';

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(recipeViewModelProvider.notifier).loadUserData(),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddRecipeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddRecipeBottomSheet(
        onAddManual: () {
          Navigator.pop(context);
          context.push(AppRoutes.addManual);
        },
        onImportLink: () {
          Navigator.pop(context);
          // TODO: import from link
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recipeViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.white,

      // ── FAB ───────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRecipeSheet,
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, color: AppColors.white, size: 28),
      ),
    );
  }
}

// ── Add Recipe Bottom Sheet ───────────────────────────────────
class _AddRecipeBottomSheet extends StatelessWidget {
  final VoidCallback onAddManual;
  final VoidCallback onImportLink;
  final VoidCallback onCancel;

  const _AddRecipeBottomSheet({
    required this.onAddManual,
    required this.onImportLink,
    required this.onCancel,
  });

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
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.gray200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppDimensions.xl),

          Text('Tambah Resep', style: AppTextStyles.h3),
          const SizedBox(height: AppDimensions.sm),
          Text(
            'Pilih cara menambahkan resep baru',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray600),
          ),
          const SizedBox(height: AppDimensions.xxl),

          // Import from link
          _OptionButton(
            icon: Icons.link_rounded,
            label: 'Impor dari Link (Blog, IG, dll)',
            onTap: onImportLink,
          ),
          const SizedBox(height: AppDimensions.md),

          // Add manual
          _OptionButton(
            icon: Icons.edit_outlined,
            label: 'Tambah Resep Manual',
            onTap: onAddManual,
          ),
          const SizedBox(height: AppDimensions.xl),

          // Cancel button
          SizedBox(
            width: double.infinity,
            height: AppDimensions.buttonHeight,
            child: ElevatedButton(
              onPressed: onCancel,
              child: const Text('Batal'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OptionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.xl,
          vertical: AppDimensions.lg,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: AppDimensions.iconXl),
            const SizedBox(width: AppDimensions.lg),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  const _EmptyState({required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilter ? Icons.search_off_rounded : Icons.menu_book_rounded,
              size: 64,
              color: AppColors.gray400,
            ),
            const SizedBox(height: AppDimensions.lg),
            Text(
              hasFilter ? 'Resep tidak ditemukan' : 'Koleksi Masih Kosong',
              style: AppTextStyles.h4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              hasFilter
                  ? 'Coba kata kunci lain'
                  : 'Tambah resep baru atau bookmark resep dari QuickMenu',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
