// Bottom sheet untuk memilih resep dari koleksi user saat menambah meal plan.
// Migrasi dari RecipeSelectionSheetContent.tsx (React Native).
// Fitur: search real-time, list resep dengan thumbnail & info.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/models/recipe_model.dart';

class RecipeSelectionSheet extends StatefulWidget {
  final List<RecipeModel> recipes;
  final bool isLoading;
  final void Function(RecipeModel recipe) onSelect;

  const RecipeSelectionSheet({
    super.key,
    required this.recipes,
    required this.onSelect,
    this.isLoading = false,
  });

  /// Tampilkan sheet secara modal.
  static Future<void> show({
    required BuildContext context,
    required List<RecipeModel> recipes,
    required void Function(RecipeModel recipe) onSelect,
    bool isLoading = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecipeSelectionSheet(
        recipes: recipes,
        onSelect: onSelect,
        isLoading: isLoading,
      ),
    );
  }

  @override
  State<RecipeSelectionSheet> createState() => _RecipeSelectionSheetState();
}

class _RecipeSelectionSheetState extends State<RecipeSelectionSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<RecipeModel> get _filtered {
    if (_query.isEmpty) return widget.recipes;
    final q = _query.toLowerCase();
    return widget.recipes
        .where((r) => r.title.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: screenH * 0.82,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXxl),
        ),
      ),
      child: Column(
        children: [
          // ── Drag Handle ─────────────────────────────────────────────────
          const SizedBox(height: AppDimensions.lg),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xxl),
            child: Row(
              children: [
                Text('Pilih Resep dari Koleksi', style: AppTextStyles.h3),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.gray400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.lg),

          // ── Search Bar ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xxl),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Cari resep...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.gray400,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.gray400,
                ),
                suffixIcon: _query.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppColors.gray400,
                          size: AppDimensions.iconMd,
                        ),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.lg,
                  vertical: AppDimensions.md,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.lg),

          // ── List ──────────────────────────────────────────────────────────
          Expanded(
            child: widget.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _filtered.isEmpty
                ? _EmptyState(hasQuery: _query.isNotEmpty)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.xxl,
                    ),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) => _RecipeTile(
                      recipe: _filtered[i],
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.onSelect(_filtered[i]);
                      },
                    ),
                  ),
          ),
          const SizedBox(height: AppDimensions.lg),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RecipeTile — satu item resep dalam list
// ─────────────────────────────────────────────────────────────────────────────

class _RecipeTile extends StatelessWidget {
  final RecipeModel recipe;
  final VoidCallback onTap;

  const _RecipeTile({required this.recipe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        child: CachedNetworkImage(
          imageUrl: recipe.imageUrl?.isNotEmpty == true
              ? recipe.imageUrl!
              : 'https://via.placeholder.com/80x80?text=No+Image',
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorWidget: (_, _, _) => Container(
            width: 56,
            height: 56,
            color: AppColors.gray200,
            child: const Icon(
              Icons.restaurant_rounded,
              color: AppColors.gray400,
            ),
          ),
        ),
      ),
      title: Text(
        recipe.title,
        style: AppTextStyles.labelMedium,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          const Icon(
            Icons.access_time_rounded,
            size: 12,
            color: AppColors.gray400,
          ),
          const SizedBox(width: 2),
          Text(recipe.durationFormatted, style: AppTextStyles.caption),
          if (recipe.primaryCategory.isNotEmpty) ...[
            const SizedBox(width: AppDimensions.sm),
            Flexible(
              child: Text(
                '#${recipe.primaryCategory}',
                style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.gray400,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EmptyState
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasQuery;
  const _EmptyState({required this.hasQuery});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasQuery
                ? Icons.search_off_rounded
                : Icons.collections_bookmark_outlined,
            size: 56,
            color: AppColors.gray100,
          ),
          const SizedBox(height: AppDimensions.md),
          Text(
            hasQuery ? 'Resep tidak ditemukan' : 'Koleksi masih kosong',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            hasQuery
                ? 'Coba kata kunci lain'
                : 'Tambahkan resep ke koleksi terlebih dahulu',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
