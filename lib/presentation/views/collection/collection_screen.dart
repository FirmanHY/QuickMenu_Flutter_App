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
import '../../../shared/widgets/category_chip_bar.dart';
import '../../../shared/widgets/recipe_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CollectionScreen
// ─────────────────────────────────────────────────────────────────────────────

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  // ── Controllers & Timers ──────────────────────────────────────
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _debounce;

  // ── Category chips ────────────────────────────────────────────
  /// Semua kategori unik dari resep user (dibangun ulang tiap state berubah)
  List<String> _categories = ['Semua'];

  @override
  void initState() {
    super.initState();
    // Load saat pertama buka
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

  /// Bangun daftar kategori unik dari resep yang ada
  void _buildCategories(List<RecipeModel> recipes) {
    final Set<String> cats = {};
    for (final r in recipes) {
      cats.addAll(r.categories);
    }
    final sorted = cats.toList()..sort();
    _categories = ['Semua', ...sorted];
  }

  // ── Handlers ──────────────────────────────────────────────────

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(recipeViewModelProvider.notifier).setSearch(value);
    });
  }

  void _onCategoryTap(String category) {
    // Reset search ketika ganti kategori agar konsisten
    _searchCtrl.clear();
    ref.read(recipeViewModelProvider.notifier).setCategory(category);
  }

  Future<void> _onRefresh() async {
    await ref.read(recipeViewModelProvider.notifier).loadUserData();
  }

  void _onRecipeTap(RecipeModel recipe) {
    context.push(AppRoutes.recipeDetailPath(recipe.id));
  }

  void _onRecipeLongPress(RecipeModel recipe) {
    _showDeleteDialog(recipe);
  }

  void _showAddRecipeSheet() {
    showModalBottomSheet<void>(
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
          // TODO: navigate to import-preview dengan URL input
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

    if (mounted) {
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
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recipeViewModelProvider);

    // ── Listen error → SnackBar ──────────────────────────────
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

    // Bangun kategori setiap kali allUserRecipes berubah
    _buildCategories(state.allUserRecipes);

    final recipes = state.filteredUserRecipes;
    final selectedCategory = state.selectedCategory;
    final hasFilter =
        state.searchQuery.isNotEmpty || selectedCategory != 'Semua';

    return Scaffold(
      backgroundColor: AppColors.white,

      // ── FAB ─────────────────────────────────────────────────
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
          // ── Header sticky: search + chips ─────────────────
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: _CollectionHeader(
                searchCtrl: _searchCtrl,
                categories: _categories,
                selectedCategory: selectedCategory,
                onSearchChanged: _onSearchChanged,
                onCategoryTap: _onCategoryTap,
              ),
            ),
          ],
          // ── Body: grid atau empty state ───────────────────
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _onRefresh,
            child: state.isLoading
                ? const _LoadingGrid()
                : recipes.isEmpty
                ? _EmptyState(
                    hasFilter: hasFilter,
                    onAddRecipe: _showAddRecipeSheet,
                  )
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
// Header (Search + Category Chips + Result count)
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
          // Title row
          Row(
            children: [Text(AppStrings.myCollection, style: AppTextStyles.h2)],
          ),
          const SizedBox(height: AppDimensions.lg),

          // Search bar
          _SearchBar(controller: searchCtrl, onChanged: onSearchChanged),
          const SizedBox(height: AppDimensions.md),

          // Category chips — shared component
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
// Search Bar
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimensions.inputHeight,
      decoration: BoxDecoration(
        color: AppColors.gray200,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Cari resep di koleksi...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.gray400,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.gray400,
            size: AppDimensions.iconLg,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, val, _) => val.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: AppDimensions.iconMd,
                      color: AppColors.gray400,
                    ),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  )
                : const SizedBox.shrink(),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: AppDimensions.md,
          ),
        ),
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
        // Extra bottom padding agar konten tidak tertutup FAB + bottom nav
        AppDimensions.xxxxl + AppDimensions.xxxl,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppDimensions.md,
        crossAxisSpacing: AppDimensions.md,
        childAspectRatio:
            AppDimensions.recipeCardWidth /
            AppDimensions.recipeCardHeight, // 160 / 220
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
// Recipe Grid Item (wraps RecipeCard + long-press + source badge)
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
          // Kartu resep utama
          RecipeCard(
            imageUrl: recipe.imageUrl ?? '',
            title: recipe.title,
            duration: recipe.durationFormatted,
            category: recipe.categories.isNotEmpty
                ? '#${recipe.primaryCategory}'
                : null,
            variant: RecipeCardVariant.small,
            // Bookmark hanya relevan untuk QuickMenu public recipes
            showBookmark: false,
          ),

          // Source badge (pojok kanan atas)
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
// Source Badge
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
// Loading Skeleton
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
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
      itemCount: 6,
      itemBuilder: (_, _) => _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.4,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.gray200,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onAddRecipe;

  const _EmptyState({required this.hasFilter, required this.onAddRecipe});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xxxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilter ? Icons.search_off_rounded : Icons.menu_book_rounded,
              size: 72,
              color: AppColors.gray400,
            ),
            const SizedBox(height: AppDimensions.lg),
            Text(
              hasFilter ? 'Resep tidak ditemukan' : AppStrings.emptyCollection,
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              hasFilter
                  ? 'Coba kata kunci atau filter lain'
                  : AppStrings.emptyCollectionSub,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
            if (!hasFilter) ...[
              const SizedBox(height: AppDimensions.xxl),
              SizedBox(
                height: AppDimensions.buttonHeight,
                child: ElevatedButton.icon(
                  onPressed: onAddRecipe,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(AppStrings.addRecipe),
                ),
              ),
            ],
          ],
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
          Text(AppStrings.addRecipe, style: AppTextStyles.h3),
          const SizedBox(height: AppDimensions.sm),
          Text(
            'Pilih cara menambahkan resep baru',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray600),
          ),
          const SizedBox(height: AppDimensions.xxl),

          // Import from link
          _SheetOptionButton(
            icon: Icons.link_rounded,
            label: AppStrings.importFromLink,
            onTap: onImportLink,
          ),
          const SizedBox(height: AppDimensions.md),

          // Add manual
          _SheetOptionButton(
            icon: Icons.edit_outlined,
            label: AppStrings.addManual,
            onTap: onAddManual,
          ),
          const SizedBox(height: AppDimensions.xl),

          // Cancel
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
