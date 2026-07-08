import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_router.dart';
import '../../viewmodels/planner_viewmodel.dart';
import '../../viewmodels/recipe_detail_viewmodel.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/edit_tag_bottom_sheet.dart';
import '../../../shared/widgets/schedule_bottom_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final String recipeId;

  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Tab index: 0 = Bahan-Bahan, 1 = Langkah-Langkah
  static const _tabs = ['Bahan-Bahan', 'Langkah-Langkah'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Shorthand ke notifier
  RecipeDetailViewModel get _vm =>
      ref.read(recipeDetailViewModelProvider(widget.recipeId).notifier);

  // ── Event handlers ────────────────────────────────────────────────────────

  Future<void> _onToggleBookmark() => _vm.toggleBookmark();

  void _onEditRecipe() {
    context.push(AppRoutes.editRecipePath(widget.recipeId));
  }

  void _onOpenEditTag() {
    final recipe = ref
        .read(recipeDetailViewModelProvider(widget.recipeId))
        .recipe;
    if (recipe == null) return;

    EditTagBottomSheet.show(
      context: context,
      initialTags: recipe.categories,
      onSave: (tags) => _vm.saveTags(tags),
    );
  }

  void _onOpenSchedule() {
    final state = ref.read(recipeDetailViewModelProvider(widget.recipeId));
    ScheduleBottomSheet.show(
      context: context,
      isSaving: state.isSavingSchedule,
      onSave: (date, mealType) => _vm.scheduleRecipe(date, mealType),
    );
  }

  // ── Helper: warna tag konsisten berdasarkan string hash ──────────────────

  static Color _tagBg(String tag) {
    const bgs = [
      Color(0xFFE3F2FD),
      Color(0xFFE8F5E9),
      Color(0xFFFFF3E0),
      Color(0xFFF3E5F5),
      Color(0xFFF5F5F5),
    ];
    int hash = 0;
    for (final c in tag.runes) {
      hash = c + ((hash << 5) - hash);
    }
    return bgs[hash.abs() % bgs.length];
  }

  static Color _tagText(String tag) {
    const texts = [
      Color(0xFF1565C0),
      Color(0xFF2E7D32),
      Color(0xFFEF6C00),
      Color(0xFF7B1FA2),
      Color(0xFF616161),
    ];
    int hash = 0;
    for (final c in tag.runes) {
      hash = c + ((hash << 5) - hash);
    }
    return texts[hash.abs() % texts.length];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recipeDetailViewModelProvider(widget.recipeId));

    // ── Side effects: snackbar ──────────────────────────────────────────────
    ref.listen(recipeDetailViewModelProvider(widget.recipeId), (prev, next) {
      // Konfirmasi jadwal — dipisah dari successMessage biasa supaya tetap
      // muncul walau user menjadwalkan resep lain ke tanggal & slot yang sama
      // dua kali berturut-turut (lihat scheduleEventId di ViewModel).
      if (next.scheduleEventId > 0 &&
          next.scheduleEventId != prev?.scheduleEventId) {
        final date = next.scheduledDate!;
        final mealType = next.scheduledMealType!;
        final dateLabel = DateFormat('EEEE, d MMMM', 'id_ID').format(date);

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(AppDimensions.lg),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              duration: const Duration(seconds: 6),
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.white,
                    size: AppDimensions.iconMd,
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  Expanded(
                    child: Text(
                      'Resep berhasil dijadwalkan untuk $dateLabel',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
              action: SnackBarAction(
                label: 'Lihat Jadwal',
                textColor: AppColors.white,
                onPressed: () {
                  ref
                      .read(plannerViewModelProvider.notifier)
                      .jumpToDate(date, highlightMealType: mealType);
                  context.go(AppRoutes.planner);
                },
              ),
            ),
          );
      }

      if (next.successMessage != null &&
          next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.successMessage!),
              backgroundColor: AppColors.success,
            ),
          );
        _vm.clearSuccess();
      }
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
        _vm.clearError();
      }
    });

    // ── Loading ─────────────────────────────────────────────────────────────
    if (state.isLoading && state.recipe == null) {
      return const Scaffold(
        backgroundColor: AppColors.white,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // ── Error / not found ───────────────────────────────────────────────────
    if (state.recipe == null) {
      return Scaffold(
        backgroundColor: AppColors.white,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: AppColors.error,
              ),
              const SizedBox(height: AppDimensions.md),
              Text('Resep tidak ditemukan', style: AppTextStyles.bodyLarge),
              const SizedBox(height: AppDimensions.xl),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      );
    }

    final recipe = state.recipe!;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // ── Scrollable content ──────────────────────────────────────────
          CustomScrollView(
            slivers: [
              // ── Hero Image ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _HeroImage(
                  imageUrl: recipe.imageUrl ?? '',
                  isBookmarked: recipe.isBookmarked,
                  isQuickMenu: state.isQuickMenuSource,
                  onBack: () => context.pop(),
                  onBookmarkToggle: _onToggleBookmark,
                  onEdit: _onEditRecipe,
                ),
              ),

              // ── Content Sheet ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppDimensions.radiusXxl),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.xxl,
                      AppDimensions.xl,
                      AppDimensions.xxl,
                      120, // ruang untuk footer button
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // drag handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.gray100,
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusFull,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.lg),

                        // ── Judul ────────────────────────────────────────────
                        Text(recipe.title, style: AppTextStyles.h2),
                        const SizedBox(height: AppDimensions.sm),

                        // ── Durasi ───────────────────────────────────────────
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: AppDimensions.iconSm,
                              color: AppColors.gray400,
                            ),
                            const SizedBox(width: AppDimensions.xs),
                            Text(
                              recipe.durationFormatted,
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.lg),

                        // ── Tags ─────────────────────────────────────────────
                        Wrap(
                          spacing: AppDimensions.sm,
                          runSpacing: AppDimensions.sm,
                          children: [
                            ...recipe.categories.map((cat) {
                              return _TagChip(
                                label: '#$cat',
                                bgColor: _tagBg(cat),
                                textColor: _tagText(cat),
                              );
                            }),
                            // Tombol edit tag (hanya untuk resep milik user)
                            if (!state.isQuickMenuSource)
                              GestureDetector(
                                onTap: _onOpenEditTag,
                                child: Text(
                                  recipe.categories.isEmpty
                                      ? '(+ Tambah Tag)'
                                      : '(Edit Tag)',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.xxl),

                        // ── Tab Bar ───────────────────────────────────────────
                        _TabBar(controller: _tabController, tabs: _tabs),
                        const SizedBox(height: AppDimensions.xl),

                        // ── Tab Content ───────────────────────────────────────
                        _TabContent(
                          controller: _tabController,
                          ingredients: recipe.ingredients,
                          steps: recipe.steps,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Footer Button (fixed) ──────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _FooterButton(
              showAddToCollection: state.showAddToCollection,
              isLoading: state.isSavingSchedule,
              onAddToCollection: _onToggleBookmark,
              onAddToPlan: _onOpenSchedule,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Hero image full-width dengan overlay gelap + tombol back/bookmark/edit.
class _HeroImage extends StatelessWidget {
  final String imageUrl;
  final bool isBookmarked;
  final bool isQuickMenu;
  final VoidCallback onBack;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onEdit;

  const _HeroImage({
    required this.imageUrl,
    required this.isBookmarked,
    required this.isQuickMenu,
    required this.onBack,
    required this.onBookmarkToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return SizedBox(
      height: 280,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Gambar ───────────────────────────────────────────────────────
          CachedNetworkImage(
            imageUrl: imageUrl.isNotEmpty
                ? imageUrl
                : 'https://via.placeholder.com/500x300?text=No+Image',
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(color: AppColors.gray200),
            errorWidget: (_, _, _) => Container(color: AppColors.gray200),
          ),

          // ── Gradient overlay ─────────────────────────────────────────────
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.25),
                  Colors.transparent,
                  Colors.black.withOpacity(0.15),
                ],
              ),
            ),
          ),

          // ── Buttons ──────────────────────────────────────────────────────
          Positioned(
            top: top,
            left: AppDimensions.lg,
            right: AppDimensions.lg,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CircleIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: onBack,
                ),
                // QuickMenu: bookmark toggle | resep user: tombol edit
                _CircleIconButton(
                  icon: isQuickMenu
                      ? (isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded)
                      : Icons.edit_rounded,
                  iconColor: (isQuickMenu && isBookmarked)
                      ? AppColors.primary
                      : AppColors.textPrimary,
                  onTap: isQuickMenu ? onBookmarkToggle : onEdit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tombol lingkaran semi-transparan (dipakai di atas hero image).
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: AppDimensions.iconMd,
          color: iconColor ?? AppColors.textPrimary,
        ),
      ),
    );
  }
}

/// Chip warna-warni untuk tag resep.
class _TagChip extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;

  const _TagChip({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: textColor),
      ),
    );
  }
}

/// Tab bar custom dengan indicator bawah bergaya pill.
class _TabBar extends StatelessWidget {
  final TabController controller;
  final List<String> tabs;

  const _TabBar({required this.controller, required this.tabs});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.gray400,
        labelStyle: AppTextStyles.labelMedium,
        unselectedLabelStyle: AppTextStyles.bodyMedium,
        tabs: tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }
}

/// Konten tab — menampilkan HTML Bahan-Bahan atau Langkah-Langkah.
class _TabContent extends StatefulWidget {
  final TabController controller;
  final String ingredients;
  final String steps;

  const _TabContent({
    required this.controller,
    required this.ingredients,
    required this.steps,
  });

  @override
  State<_TabContent> createState() => _TabContentState();
}

class _TabContentState extends State<_TabContent> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTabChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTabChange);
    super.dispose();
  }

  void _onTabChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isIngredients = widget.controller.index == 0;
    final html = isIngredients ? widget.ingredients : widget.steps;

    if (html.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.xxxl),
        child: Center(
          child: Text('Tidak ada data.', style: AppTextStyles.bodyMedium),
        ),
      );
    }

    return Html(
      data: html,
      style: {
        'body': Style(
          fontSize: FontSize(14),
          color: AppColors.textPrimary,
          lineHeight: const LineHeight(1.6),
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
        ),
        'p': Style(margin: Margins.only(bottom: 10)),
        'li': Style(margin: Margins.only(bottom: 6)),
        'ul': Style(
          margin: Margins.only(bottom: 10),
          padding: HtmlPaddings.only(left: 20),
        ),
        'ol': Style(
          margin: Margins.only(bottom: 10),
          padding: HtmlPaddings.only(left: 20),
        ),
        'b': Style(fontWeight: FontWeight.bold),
        'strong': Style(fontWeight: FontWeight.bold),
      },
    );
  }
}

/// Footer button yang menempel di bawah layar.
/// Adaptif: "Tambahkan ke Koleksi" atau "Tambahkan ke Rencana Menu".
class _FooterButton extends StatelessWidget {
  final bool showAddToCollection;
  final bool isLoading;
  final VoidCallback onAddToCollection;
  final VoidCallback onAddToPlan;

  const _FooterButton({
    required this.showAddToCollection,
    required this.isLoading,
    required this.onAddToCollection,
    required this.onAddToPlan,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.xxl,
        AppDimensions.lg,
        AppDimensions.xxl,
        AppDimensions.lg + bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: AppButton(
        title: showAddToCollection
            ? 'Tambahkan ke Koleksi'
            : 'Tambahkan ke Rencana Menu',
        onPressed: showAddToCollection ? onAddToCollection : onAddToPlan,
        isLoading: isLoading,
      ),
    );
  }
}
