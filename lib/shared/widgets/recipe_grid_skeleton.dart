//
// Loading skeleton (shimmer-like pulse) untuk grid resep 2 kolom.
// Dipakai di: ExploreScreen, CollectionScreen.
//
// Usage:
//   // Ganti kondisi loading dengan widget ini:
//   if (state.isLoading)
//     const RecipeGridSkeleton()
//
//   // Opsional — ubah jumlah card dan bottom padding:
//   RecipeGridSkeleton(itemCount: 4, bottomPadding: 80)

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RecipeGridSkeleton
// ─────────────────────────────────────────────────────────────────────────────

class RecipeGridSkeleton extends StatelessWidget {
  /// Jumlah skeleton card yang ditampilkan (default 6).
  final int itemCount;

  /// Extra bottom padding agar tidak tertutup FAB / bottom nav (default 48).
  final double bottomPadding;

  /// Apakah scroll diaktifkan (default false — agar tidak konflik dgn parent scroll).
  final bool scrollable;

  const RecipeGridSkeleton({
    super.key,
    this.itemCount = 6,
    this.bottomPadding = AppDimensions.xxxxl,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: scrollable
          ? const AlwaysScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppDimensions.screenHorizontal,
        AppDimensions.sm,
        AppDimensions.screenHorizontal,
        bottomPadding,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppDimensions.md,
        crossAxisSpacing: AppDimensions.md,
        childAspectRatio:
            AppDimensions.recipeCardWidth / AppDimensions.recipeCardHeight,
      ),
      itemCount: itemCount,
      itemBuilder: (_, _) => const _SkeletonCard(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SkeletonCard — single animated card placeholder
// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

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
      end: 1.0,
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
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Padding(
              padding: const EdgeInsets.all(8),
              child: _SkeletonBox(
                width: double.infinity,
                height: 110,
                borderRadius: 12,
              ),
            ),
            // Text placeholders
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SkeletonBox(width: double.infinity, height: 13),
                  const SizedBox(height: 6),
                  const _SkeletonBox(width: 80, height: 13),
                  const SizedBox(height: 10),
                  const _SkeletonBox(width: 60, height: 11),
                  const SizedBox(height: 6),
                  const _SkeletonBox(width: 50, height: 11),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SkeletonBox — building block untuk skeleton shape
// (public agar bisa dipakai di skeleton lain, mis. ChipBar skeleton)
// ─────────────────────────────────────────────────────────────────────────────

class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppDimensions.radiusSm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

// Private alias (sama dengan SkeletonBox tapi const constructor).
class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    this.borderRadius = AppDimensions.radiusSm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CategoryChipBarSkeleton
// Loading placeholder untuk horizontal chip bar.
// Dipakai saat kategori masih di-fetch dari Firebase.
// ─────────────────────────────────────────────────────────────────────────────

class CategoryChipBarSkeleton extends StatefulWidget {
  /// Jumlah chip skeleton (default 5).
  final int itemCount;

  const CategoryChipBarSkeleton({super.key, this.itemCount = 5});

  @override
  State<CategoryChipBarSkeleton> createState() =>
      _CategoryChipBarSkeletonState();
}

class _CategoryChipBarSkeletonState extends State<CategoryChipBarSkeleton>
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
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Variasi lebar chip agar terlihat natural
    const widths = [72.0, 88.0, 64.0, 96.0, 80.0];

    return FadeTransition(
      opacity: _anim,
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenHorizontal,
          ),
          itemCount: widget.itemCount,
          separatorBuilder: (_, _) => const SizedBox(width: AppDimensions.sm),
          itemBuilder: (_, i) => _SkeletonBox(
            width: widths[i % widths.length],
            height: 32,
            borderRadius: AppDimensions.radiusFull,
          ),
        ),
      ),
    );
  }
}
