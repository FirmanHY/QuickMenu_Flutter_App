// lib/shared/widgets/empty_state.dart
//
// Widget empty state reusable dengan konfigurasi fleksibel.
// Dipakai di: ExploreScreen, CollectionScreen, HomeScreen, dan screen lainnya.
//
// Usage — Explore (search/filter kosong):
//   EmptyState(
//     icon: Icons.search_off_rounded,
//     title: 'Resep Tidak Ditemukan',
//     subtitle: 'Coba kata kunci atau kategori yang berbeda',
//     action: EmptyStateAction(
//       label: 'Reset Filter',
//       icon: Icons.refresh_rounded,
//       onPressed: _resetFilter,
//     ),
//   )
//
// Usage — Collection (koleksi kosong):
//   EmptyState.collection(onAddRecipe: _showAddSheet)
//
// Usage — Home (section resep kosong):
//   EmptyState.section(message: 'Belum ada resep sehat.')

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EmptyStateAction — data class untuk tombol CTA opsional
// ─────────────────────────────────────────────────────────────────────────────

class EmptyStateAction {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  const EmptyStateAction({
    required this.label,
    this.icon,
    required this.onPressed,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// EmptyState
// ─────────────────────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  /// Icon utama yang ditampilkan dalam lingkaran.
  final IconData icon;

  /// Judul bold di bawah icon.
  final String title;

  /// Subtitle/deskripsi lebih kecil (opsional).
  final String? subtitle;

  /// Tombol aksi opsional (mis. "Reset Filter", "Tambah Resep").
  final EmptyStateAction? action;

  /// Ukuran container icon (default 100).
  final double iconContainerSize;

  /// Ukuran icon di dalam container (default 48).
  final double iconSize;

  /// Warna background lingkaran icon (default primary light).
  final Color? iconBgColor;

  /// Warna icon (default primary).
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.iconContainerSize = 100,
    this.iconSize = 48,
    this.iconBgColor,
    this.iconColor,
  });

  // ── Named constructors untuk use case umum ────────────────────────────────

  /// Koleksi user masih kosong (belum tambah resep).
  factory EmptyState.collection({required VoidCallback onAddRecipe}) {
    return EmptyState(
      icon: Icons.menu_book_rounded,
      title: 'Koleksi Masih Kosong',
      subtitle: 'Mulai tambahkan resep favoritmu',
      action: EmptyStateAction(
        label: 'Tambah Resep',
        icon: Icons.add_rounded,
        onPressed: onAddRecipe,
      ),
    );
  }

  /// Hasil search / filter tidak ada.
  factory EmptyState.noResults({VoidCallback? onReset}) {
    return EmptyState(
      icon: Icons.search_off_rounded,
      title: 'Resep Tidak Ditemukan',
      subtitle: 'Coba kata kunci atau kategori yang berbeda',
      action: onReset != null
          ? EmptyStateAction(
              label: 'Reset Filter',
              icon: Icons.refresh_rounded,
              onPressed: onReset,
            )
          : null,
    );
  }

  /// Versi ringkas untuk section dalam scroll (Home screen, dsb).
  /// Tidak ada icon container besar — hanya icon kecil + teks.
  /// Karena const constructor, bisa dipakai dalam const context.
  ///
  /// Usage:
  ///   const EmptyState.section(message: 'Belum ada resep sehat.')
  const EmptyState.section({
    Key? key,
    required String message,
    IconData icon = Icons.no_food_rounded,
  }) : this(
         key: key,
         icon: icon,
         title: message,
         iconContainerSize: 64,
         iconSize: 36,
         iconBgColor: Colors.transparent,
         iconColor: AppColors.gray400,
       );

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final effectiveIconBg =
        iconBgColor ?? AppColors.primaryLight.withOpacity(0.3);
    final effectiveIconColor = iconColor ?? AppColors.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Icon ──────────────────────────────────────────────
            Container(
              width: iconContainerSize,
              height: iconContainerSize,
              decoration: BoxDecoration(
                color: effectiveIconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: iconSize, color: effectiveIconColor),
            ),

            const SizedBox(height: AppDimensions.xl),

            // ── Title ─────────────────────────────────────────────
            Text(title, style: AppTextStyles.h3, textAlign: TextAlign.center),

            // ── Subtitle ──────────────────────────────────────────
            if (subtitle != null) ...[
              const SizedBox(height: AppDimensions.sm),
              Text(
                subtitle!,
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],

            // ── CTA Button ────────────────────────────────────────
            if (action != null) ...[
              const SizedBox(height: AppDimensions.xl),
              OutlinedButton(
                onPressed: action!.onPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.xl,
                    vertical: AppDimensions.sm,
                  ),
                  minimumSize: Size.zero,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (action!.icon != null) ...[
                      Icon(action!.icon, size: 18),
                      const SizedBox(width: AppDimensions.xs),
                    ],
                    Text(
                      action!.label,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
