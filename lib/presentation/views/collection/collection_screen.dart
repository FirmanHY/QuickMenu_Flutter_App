import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_router.dart';
import '../../../data/models/recipe_model.dart';
import '../../../presentation/viewmodels/recipe_viewmodel.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/category_chip_bar.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/recipe_card.dart';
import '../../../shared/widgets/recipe_grid_skeleton.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CollectionScreen
// ─────────────────────────────────────────────────────────────────────────────

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _debounce;

  List<String> _categories = ['Semua'];

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
    _scrollCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────

  void _buildCategories(List<RecipeModel> recipes) {
    final cats = <String>{};
    for (final r in recipes) {
      cats.addAll(r.categories);
    }
    _categories = ['Semua', ...cats.toList()..sort()];
  }

  // ── Handlers ──────────────────────────────────────────────────

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(recipeViewModelProvider.notifier).setSearch(value);
    });
  }

  void _onCategoryTap(String category) {
    _searchCtrl.clear();
    ref.read(recipeViewModelProvider.notifier).setCategory(category);
  }

  Future<void> _onRefresh() async =>
      ref.read(recipeViewModelProvider.notifier).loadUserData();

  void _onRecipeTap(RecipeModel recipe) =>
      context.push(AppRoutes.recipeDetailPath(recipe.id));

  void _onRecipeLongPress(RecipeModel recipe) => _showDeleteDialog(recipe);

  void _showAddRecipeSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddRecipeBottomSheet(
        onAddManual: () async {
          Navigator.pop(context);
          await context.push(AppRoutes.addManual);
          if (mounted) {
            ref.read(recipeViewModelProvider.notifier).loadUserData();
          }
        },
        onImportLink: () async {
          Navigator.pop(context);
          await context.push(AppRoutes.importUrl);
          if (mounted) {
            ref.read(recipeViewModelProvider.notifier).loadUserData();
          }
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _showDeleteDialog(RecipeModel recipe) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        title: Text('Hapus Resep?', style: AppTextStyles.h4),
        content: Text(
          'Resep "${recipe.title}" akan dihapus dari koleksi kamu. Tindakan ini tidak bisa dibatalkan.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppStrings.cancel,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.gray600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteRecipe(recipe);
            },
            child: Text(
              AppStrings.delete,
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRecipe(RecipeModel recipe) async {
    final success = await ref
        .read(recipeViewModelProvider.notifier)
        .deleteRecipe(recipe.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? AppStrings.successDeleteRecipe
                : 'Gagal menghapus resep. Coba lagi.',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppDimensions.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
        ),
      );
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recipeViewModelProvider);

    ref.listen<RecipeState>(recipeViewModelProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(AppDimensions.lg),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
            ),
          );
        ref.read(recipeViewModelProvider.notifier).clearError();
      }
    });

    _buildCategories(state.allUserRecipes);

    final recipes = state.filteredUserRecipes;
    final hasFilter =
        state.searchQuery.isNotEmpty || state.selectedCategory != 'Semua';

    return Scaffold(
      backgroundColor: AppColors.white,

      // ── FAB ───────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRecipeSheet,
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(
          Icons.add_rounded,
          color: AppColors.white,
          size: AppDimensions.iconXl,
        ),
      ),

      body: SafeArea(
        child: NestedScrollView(
          controller: _scrollCtrl,
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: _CollectionHeader(
                searchCtrl: _searchCtrl,
                categories: _categories,
                selectedCategory: state.selectedCategory,
                onSearchChanged: _onSearchChanged,
                onCategoryTap: _onCategoryTap,
              ),
            ),
          ],
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _onRefresh,
            child: state.isLoading
                // ── Loading → shared RecipeGridSkeleton ──────────
                ? RecipeGridSkeleton(
                    bottomPadding: AppDimensions.xxxxl + AppDimensions.xxxl,
                  )
                : recipes.isEmpty
                // ── Empty → shared EmptyState ─────────────────────
                ? (hasFilter
                      ? EmptyState.noResults(
                          onReset: () {
                            _searchCtrl.clear();
                            ref
                                .read(recipeViewModelProvider.notifier)
                                .setCategory('Semua');
                          },
                        )
                      : EmptyState.collection(onAddRecipe: _showAddRecipeSheet))
                // ── Normal → recipe grid ──────────────────────────
                : _RecipeGrid(
                    recipes: recipes,
                    onTap: _onRecipeTap,
                    onLongPress: _onRecipeLongPress,
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header — AppInput search + CategoryChipBar
// ─────────────────────────────────────────────────────────────────────────────

class _CollectionHeader extends StatelessWidget {
  final TextEditingController searchCtrl;
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategoryTap;

  const _CollectionHeader({
    required this.searchCtrl,
    required this.categories,
    required this.selectedCategory,
    required this.onSearchChanged,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.screenHorizontal,
        AppDimensions.lg,
        AppDimensions.screenHorizontal,
        AppDimensions.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title ──────────────────────────────────────────
          Text(AppStrings.myCollection, style: AppTextStyles.h2),
          const SizedBox(height: AppDimensions.lg),

          // ── Search — AppInput dengan showClearButton ────────
          AppInput(
            controller: searchCtrl,
            placeholder: 'Cari resep di koleksi...',
            prefixIcon: Icons.search_rounded,
            showClearButton: true,
            bottomSpacing: AppDimensions.md,
            onChanged: onSearchChanged,
          ),

          // ── Category chips — CategoryChipBar ────────────────
          CategoryChipBar(
            categories: categories,
            selected: selectedCategory,
            onSelected: onCategoryTap,
          ),
          const SizedBox(height: AppDimensions.md),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recipe Grid
// ─────────────────────────────────────────────────────────────────────────────

class _RecipeGrid extends StatelessWidget {
  final List<RecipeModel> recipes;
  final ValueChanged<RecipeModel> onTap;
  final ValueChanged<RecipeModel> onLongPress;

  const _RecipeGrid({
    required this.recipes,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.screenHorizontal,
        AppDimensions.sm,
        AppDimensions.screenHorizontal,
        AppDimensions.xxxxl + AppDimensions.xxxl,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppDimensions.md,
        crossAxisSpacing: AppDimensions.md,
        childAspectRatio:
            AppDimensions.recipeCardWidth / AppDimensions.recipeCardHeight,
      ),
      itemCount: recipes.length,
      itemBuilder: (_, i) {
        final recipe = recipes[i];
        return _RecipeGridItem(
          recipe: recipe,
          onTap: () => onTap(recipe),
          onLongPress: () => onLongPress(recipe),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recipe Grid Item — RecipeCard + long-press + source badge
// ─────────────────────────────────────────────────────────────────────────────

class _RecipeGridItem extends StatelessWidget {
  final RecipeModel recipe;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _RecipeGridItem({
    required this.recipe,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        children: [
          RecipeCard(
            imageUrl: recipe.imageUrl ?? '',
            title: recipe.title,
            duration: recipe.durationFormatted,
            category: recipe.categories.isNotEmpty
                ? '#${recipe.primaryCategory}'
                : null,
            variant: RecipeCardVariant.small,
            showBookmark: false,
          ),
          Positioned(
            top: 14,
            right: 14,
            child: _SourceBadge(source: recipe.source),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Source Badge — private, hanya relevan di Collection
// ─────────────────────────────────────────────────────────────────────────────

class _SourceBadge extends StatelessWidget {
  final String source;

  const _SourceBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (source.toLowerCase()) {
      'quickmenu' => ('QM', AppColors.primary, AppColors.white),
      'manual' => ('✎', AppColors.lime, AppColors.primary),
      'instagram' => ('IG', const Color(0xFFE1306C), AppColors.white),
      'tiktok' => ('TK', AppColors.black, AppColors.white),
      'youtube' => ('YT', const Color(0xFFFF0000), AppColors.white),
      _ => ('🔗', AppColors.gray200, AppColors.gray600),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Recipe Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

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
            onTap: onImportLink,
          ),
          const SizedBox(height: AppDimensions.md),
          _SheetOptionButton(
            icon: Icons.edit_outlined,
            label: AppStrings.addManual,
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
  final VoidCallback onTap;

  const _SheetOptionButton({
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
