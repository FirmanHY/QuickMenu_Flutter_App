import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_router.dart';
import '../../../data/models/recipe_model.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/category_chip_bar.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/recipe_card.dart';
import '../../../shared/widgets/recipe_grid_skeleton.dart';
import '../../viewmodels/explore_viewmodel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ExploreScreen
// ─────────────────────────────────────────────────────────────────────────────

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(exploreViewModelProvider.notifier).loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  void _onSearchChanged(String value) =>
      ref.read(exploreViewModelProvider.notifier).setSearchQuery(value);

  void _onCategorySelected(String category) =>
      ref.read(exploreViewModelProvider.notifier).selectCategory(category);

  Future<void> _onRefresh() async =>
      ref.read(exploreViewModelProvider.notifier).refresh();

  void _onBookmarkTap(RecipeModel recipe) => ref
      .read(exploreViewModelProvider.notifier)
      .toggleBookmark(recipe.id, recipe.isBookmarked);

  void _onRecipeTap(RecipeModel recipe) =>
      context.push(AppRoutes.recipeDetailPath(recipe.id));

  void _resetFilter() {
    _searchController.clear();
    ref.read(exploreViewModelProvider.notifier)
      ..clearSearch()
      ..selectCategory('Semua');
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exploreViewModelProvider);

    // Error snackbar
    ref.listen(exploreViewModelProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    });

    final categoryLabels = ['Semua', ...state.categories.map((c) => c.name)];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────
            const _ExploreHeader(),

            // ── Search Bar — pakai AppInput dengan showClearButton ──
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.screenHorizontal,
                AppDimensions.sm,
                AppDimensions.screenHorizontal,
                0,
              ),
              child: AppInput(
                controller: _searchController,
                placeholder: AppStrings.searchRecipe,
                prefixIcon: Icons.search_rounded,
                showClearButton: true,
                bottomSpacing: AppDimensions.md,
                onChanged: _onSearchChanged,
              ),
            ),

            // ── Category Chips ───────────────────────────────────
            if (state.isLoading)
              const CategoryChipBarSkeleton()
            else
              CategoryChipBar(
                categories: categoryLabels,
                selected: state.selectedCategory,
                onSelected: _onCategorySelected,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.screenHorizontal,
                ),
              ),

            const SizedBox(height: AppDimensions.sm),

            // ── Body ─────────────────────────────────────────────
            Expanded(
              child: state.isLoading
                  ? const RecipeGridSkeleton(itemCount: 6)
                  : state.isEmpty
                  ? EmptyState.noResults(
                      onReset:
                          (state.searchQuery.isNotEmpty ||
                              state.selectedCategory != 'Semua')
                          ? _resetFilter
                          : null,
                    )
                  : _ExploreGrid(
                      recipes: state.filteredRecipes,
                      onRefresh: _onRefresh,
                      onTap: _onRecipeTap,
                      onBookmark: _onBookmarkTap,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _ExploreHeader extends StatelessWidget {
  const _ExploreHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.screenHorizontal,
        AppDimensions.lg,
        AppDimensions.screenHorizontal,
        AppDimensions.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.explore, style: AppTextStyles.h2),
          const SizedBox(height: 2),
          Text(
            'Temukan resep terbaik dari QuickMenu',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Explore Grid
// ─────────────────────────────────────────────────────────────────────────────

class _ExploreGrid extends StatelessWidget {
  final List<RecipeModel> recipes;
  final Future<void> Function() onRefresh;
  final ValueChanged<RecipeModel> onTap;
  final ValueChanged<RecipeModel> onBookmark;

  const _ExploreGrid({
    required this.recipes,
    required this.onRefresh,
    required this.onTap,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.screenHorizontal,
          AppDimensions.sm,
          AppDimensions.screenHorizontal,
          AppDimensions.xxxxl,
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
          return RecipeCard(
            imageUrl: recipe.imageUrl ?? '',
            title: recipe.title,
            duration: recipe.durationFormatted,
            category: recipe.categories.isNotEmpty
                ? '#${recipe.primaryCategory}'
                : null,
            variant: RecipeCardVariant.small,
            showBookmark: true,
            isBookmarked: recipe.isBookmarked,
            onPress: () => onTap(recipe),
            onBookmarkPress: () => onBookmark(recipe),
          );
        },
      ),
    );
  }
}
