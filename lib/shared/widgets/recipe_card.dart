import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';

enum RecipeCardVariant { large, small }

class RecipeCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String duration;
  final String? category;
  final RecipeCardVariant variant;
  final bool showBookmark;
  final bool isBookmarked;
  final VoidCallback? onPress;
  final VoidCallback? onBookmarkPress;

  const RecipeCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.duration,
    this.category,
    this.variant = RecipeCardVariant.large,
    this.showBookmark = false,
    this.isBookmarked = false,
    this.onPress,
    this.onBookmarkPress,
  });

  bool get _isLarge => variant == RecipeCardVariant.large;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPress,
      child: Container(
        width: _isLarge ? 240 : 160,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: imageUrl.isNotEmpty
                          ? imageUrl
                          : 'https://via.placeholder.com/300x200?text=No+Image',
                      width: double.infinity,
                      height: _isLarge ? 150 : 110,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppColors.gray200,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.gray200,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.gray400,
                          size: 32,
                        ),
                      ),
                    ),

                    // Bookmark button
                    if (showBookmark)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: GestureDetector(
                          onTap: onBookmarkPress,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              size: 20,
                              color: isBookmarked
                                  ? AppColors.primary
                                  : AppColors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Info ─────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: _isLarge
                        ? AppTextStyles.labelLarge
                        : AppTextStyles.labelMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: AppColors.gray400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$duration Min',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                  if (category != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      category!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}