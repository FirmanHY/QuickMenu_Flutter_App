import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../data/models/meal_plan_model.dart';
import '../../data/models/recipe_model.dart';
import '../../data/repositories/planner_repository.dart';
import '../../data/repositories/recipe_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class RecipeDetailState {
  final RecipeModel? recipe;
  final bool isLoading;
  final bool isSavingSchedule;
  final bool isSavingTags;
  final String? errorMessage;
  final String? successMessage;

  // ── Info jadwal terakhir yang berhasil disimpan ──────────────────────────
  // `scheduleEventId` dipakai (bukan compare string) supaya listener di View
  // tetap ke-trigger walau user menjadwalkan resep lain ke tanggal & slot
  // yang persis sama dua kali berturut-turut.
  final DateTime? scheduledDate;
  final MealType? scheduledMealType;
  final int scheduleEventId;

  const RecipeDetailState({
    this.recipe,
    this.isLoading = false,
    this.isSavingSchedule = false,
    this.isSavingTags = false,
    this.errorMessage,
    this.successMessage,
    this.scheduledDate,
    this.scheduledMealType,
    this.scheduleEventId = 0,
  });

  bool get isQuickMenuSource => recipe?.source == 'QuickMenu';

  bool get showAddToCollection =>
      isQuickMenuSource && recipe?.isBookmarked == false;

  RecipeDetailState copyWith({
    RecipeModel? recipe,
    bool? isLoading,
    bool? isSavingSchedule,
    bool? isSavingTags,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
    DateTime? scheduledDate,
    MealType? scheduledMealType,
    int? scheduleEventId,
  }) => RecipeDetailState(
    recipe: recipe ?? this.recipe,
    isLoading: isLoading ?? this.isLoading,
    isSavingSchedule: isSavingSchedule ?? this.isSavingSchedule,
    isSavingTags: isSavingTags ?? this.isSavingTags,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    successMessage: clearSuccess
        ? null
        : (successMessage ?? this.successMessage),
    scheduledDate: scheduledDate ?? this.scheduledDate,
    scheduledMealType: scheduledMealType ?? this.scheduledMealType,
    scheduleEventId: scheduleEventId ?? this.scheduleEventId,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

final recipeRepositoryForDetailProvider = Provider<RecipeRepository>(
  (ref) => RecipeRepository(),
);

final plannerRepositoryForDetailProvider = Provider<PlannerRepository>(
  (ref) => PlannerRepository(),
);

// Riverpod 3: NotifierProvider.family — notifier receives arg via constructor
final recipeDetailViewModelProvider =
    NotifierProvider.family<RecipeDetailViewModel, RecipeDetailState, String>(
      (recipeId) => RecipeDetailViewModel(recipeId),
    );

// ─────────────────────────────────────────────────────────────────────────────
// ViewModel
// ─────────────────────────────────────────────────────────────────────────────

class RecipeDetailViewModel extends Notifier<RecipeDetailState> {
  final String recipeId;

  RecipeDetailViewModel(this.recipeId);

  @override
  RecipeDetailState build() {
    Future.microtask(() => loadRecipe(recipeId));
    return const RecipeDetailState(isLoading: true);
  }

  RecipeRepository get _recipeRepo =>
      ref.read(recipeRepositoryForDetailProvider);
  PlannerRepository get _plannerRepo =>
      ref.read(plannerRepositoryForDetailProvider);

  // ── Load ─────────────────────────────────────────────────────────────────

  Future<void> loadRecipe(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final recipe = await _recipeRepo.getRecipeById(id);
      state = state.copyWith(recipe: recipe, isLoading: false);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat resep',
      );
    }
  }

  // ── Toggle Bookmark (optimistic) ─────────────────────────────────────────

  Future<void> toggleBookmark() async {
    final recipe = state.recipe;
    if (recipe == null) return;

    final newVal = !recipe.isBookmarked;
    state = state.copyWith(recipe: recipe.copyWith(isBookmarked: newVal));

    try {
      await _recipeRepo.toggleBookmark(recipe.id, newVal);
      state = state.copyWith(
        successMessage: newVal ? 'Disimpan ke Koleksi' : 'Dihapus dari Koleksi',
      );
    } catch (_) {
      state = state.copyWith(
        recipe: recipe.copyWith(isBookmarked: recipe.isBookmarked),
        errorMessage: 'Gagal mengubah bookmark',
      );
    }
  }

  // ── Save Tags ────────────────────────────────────────────────────────────

  Future<void> saveTags(List<String> newTags) async {
    final recipe = state.recipe;
    if (recipe == null) return;

    state = state.copyWith(isSavingTags: true, clearError: true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      for (final tag in newTags) {
        final clean = tag.trim();
        if (clean.isEmpty) continue;
        try {
          await _recipeRepo.ensureUserCategory(uid, clean);
        } catch (_) {
          // Non-fatal
        }
      }

      final updated = recipe.copyWith(categories: newTags);
      await _recipeRepo.updateRecipe(recipe.id, updated);

      state = state.copyWith(
        recipe: updated,
        isSavingTags: false,
        successMessage: 'Tag berhasil diperbarui',
      );
    } on AppException catch (e) {
      state = state.copyWith(isSavingTags: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isSavingTags: false,
        errorMessage: 'Gagal menyimpan tag',
      );
    }
  }

  // ── Schedule (Add to Meal Plan) ──────────────────────────────────────────

  Future<void> scheduleRecipe(DateTime date, MealType mealType) async {
    final recipe = state.recipe;
    if (recipe == null) return;

    state = state.copyWith(isSavingSchedule: true, clearError: true);
    try {
      final dateKey = _fmt(date);
      final meal = MealItemModel(
        id: mealType.name,
        recipeId: recipe.id,
        title: recipe.title,
        imageUrl: recipe.imageUrl,
      );
      await _plannerRepo.saveMeal(dateKey, mealType, meal);

      state = state.copyWith(
        isSavingSchedule: false,
        scheduledDate: date,
        scheduledMealType: mealType,
        scheduleEventId: state.scheduleEventId + 1,
      );
    } on AppException catch (e) {
      state = state.copyWith(isSavingSchedule: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isSavingSchedule: false,
        errorMessage: 'Gagal menyimpan jadwal',
      );
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void clearError() => state = state.copyWith(clearError: true);
  void clearSuccess() => state = state.copyWith(clearSuccess: true);

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
