import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_router.dart';
import '../../../data/models/meal_plan_model.dart';
import '../../../data/models/recipe_model.dart';
import '../../viewmodels/planner_viewmodel.dart';
import '../../../shared/widgets/daily_meal_card.dart';
import '../../../shared/widgets/recipe_selection_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  static final routeObserver = RouteObserver<ModalRoute<void>>();

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> with RouteAware {
  // True when the bottom sheet is open — prevents didPopNext from reloading
  // and overwriting the optimistic update from addMeal.
  bool _sheetOpen = false;

  // GlobalKey per tanggal — dipakai untuk auto-scroll ke kartu yang di-highlight.
  final _dayKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    // Reload every time this screen mounts (e.g. switching to the Planner tab
    // after scheduling a recipe from RecipeDetail on another tab).
    Future.microtask(
      () => ref.read(plannerViewModelProvider.notifier).loadCurrentWeek(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    PlannerScreen.routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    PlannerScreen.routeObserver.unsubscribe(this);
    super.dispose();
  }

  /// Called when returning to this screen (e.g. pop from RecipeDetail).
  /// Skip reload when it was the selection sheet that closed.
  @override
  void didPopNext() {
    if (_sheetOpen) {
      _sheetOpen = false;
      return;
    }
    ref.read(plannerViewModelProvider.notifier).loadCurrentWeek();
  }

  PlannerViewModel get _vm => ref.read(plannerViewModelProvider.notifier);

  // ── Handler: Tambah Meal ──────────────────────────────────────────────────

  void _onAddMeal(String date, MealType type) {
    final state = ref.read(plannerViewModelProvider);
    _sheetOpen = true;

    RecipeSelectionSheet.show(
      context: context,
      recipes: state.collectionRecipes,
      isLoading: state.isLoadingCollection,
      onSelect: (RecipeModel recipe) {
        final meal = MealItemModel(
          id: type.name,
          recipeId: recipe.id,
          title: recipe.title,
          imageUrl: recipe.imageUrl ?? '',
        );
        _vm.addMeal(date, type, meal);
      },
    );
  }

  // ── Handler: Hapus Meal (dengan konfirmasi) ───────────────────────────────

  Future<void> _onRemoveMeal(String date, MealType type) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Menu?'),
        content: Text(
          'Hapus ${type.label} dari jadwal ini?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _vm.removeMeal(date, type);
    }
  }

  // ── Handler: Tap Meal → Detail Resep ─────────────────────────────────────

  void _onPressMeal(String recipeId) {
    context.push(AppRoutes.recipeDetailPath(recipeId));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatDateDisplay(String dateKey) {
    try {
      final date = DateTime.parse(dateKey);
      return DateFormat('EEEE, d MMMM', 'id_ID').format(date);
    } catch (_) {
      return dateKey;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(plannerViewModelProvider);

    // ── Side effects: Snackbar ────────────────────────────────────────────
    ref.listen(plannerViewModelProvider, (prev, next) {
      if (next.successMessage != null &&
          next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.successMessage!),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(AppDimensions.lg),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
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
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(AppDimensions.lg),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
            ),
          );
        _vm.clearError();
      }

      // ── Highlight: scroll ke tanggal tujuan setelah reload selesai,
      // lalu clear highlight otomatis setelah ~2 detik.
      if (next.highlightDateKey != null &&
          prev?.isLoading == true &&
          next.isLoading == false) {
        final targetKey = next.highlightDateKey;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final key = _dayKeys[targetKey];
          final ctx = key?.currentContext;
          if (ctx != null) {
            Scrollable.ensureVisible(
              ctx,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              alignment: 0.1,
            );
          }
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _vm.clearHighlight();
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text('Rencana Menu'),
        centerTitle: false,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: Column(
        children: [
          // ── Week Navigator ──────────────────────────────────────────────
          _WeekNavigator(
            label: state.weekLabel,
            onPrev: () => _vm.goPrevWeek(),
            onNext: () => _vm.goNextWeek(),
          ),

          // ── Konten ──────────────────────────────────────────────────────
          Expanded(
            child: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () => _vm.loadCurrentWeek(),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppDimensions.xxl,
                        AppDimensions.xl,
                        AppDimensions.xxl,
                        AppDimensions.xxxxl,
                      ),
                      itemCount: state.weeklyPlan.length,
                      itemBuilder: (_, i) {
                        final day = state.weeklyPlan[i];
                        final key = _dayKeys.putIfAbsent(
                          day.date,
                          () => GlobalKey(),
                        );
                        return DailyMealCard(
                          key: key,
                          day: day,
                          dateDisplay: _formatDateDisplay(day.date),
                          onAdd: (type) => _onAddMeal(day.date, type),
                          onRemove: (type) => _onRemoveMeal(day.date, type),
                          onPressMeal: _onPressMeal,
                          highlightMealType: day.date == state.highlightDateKey
                              ? state.highlightMealType
                              : null,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _WeekNavigator: row prev / label / next
// ─────────────────────────────────────────────────────────────────────────────

class _WeekNavigator extends StatelessWidget {
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _WeekNavigator({
    required this.label,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.xxl,
        vertical: AppDimensions.lg,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.gray200,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: Row(
          children: [
            // Prev
            _NavButton(icon: Icons.chevron_left_rounded, onTap: onPrev),

            // Label minggu
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelMedium,
              ),
            ),

            // Next
            _NavButton(icon: Icons.chevron_right_rounded, onTap: onNext),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.sm),
        child: Icon(
          icon,
          size: AppDimensions.iconLg,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
