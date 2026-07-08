import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/errors/app_exception.dart';
import '../../data/models/meal_plan_model.dart';
import '../../data/models/recipe_model.dart';
import '../../data/repositories/planner_repository.dart';
import '../../data/repositories/recipe_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

final plannerRepositoryProvider = Provider<PlannerRepository>(
  (ref) => PlannerRepository(),
);

final recipeRepositoryForPlannerProvider = Provider<RecipeRepository>(
  (ref) => RecipeRepository(),
);

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class PlannerState {
  final List<DailyMealPlanModel> weeklyPlan;
  final DateTime currentWeekStart;
  final bool isLoading;
  final bool isLoadingCollection;
  final List<RecipeModel> collectionRecipes;
  final String? errorMessage;
  final String? successMessage;

  // ── Highlight sementara — dipakai saat lompat ke tanggal tertentu dari
  // CTA "Lihat Jadwal" (RecipeDetail) supaya slot yang baru dijadwalkan
  // langsung kelihatan oleh user. `date` pakai format yyyy-MM-dd, sama
  // dengan DailyMealPlanModel.date.
  final String? highlightDateKey;
  final MealType? highlightMealType;

  const PlannerState({
    this.weeklyPlan = const [],
    required this.currentWeekStart,
    this.isLoading = false,
    this.isLoadingCollection = false,
    this.collectionRecipes = const [],
    this.errorMessage,
    this.successMessage,
    this.highlightDateKey,
    this.highlightMealType,
  });

  /// Label range minggu aktif, contoh: "Minggu ini (16 – 22 Jun)"
  String get weekLabel {
    final fmt = DateFormat('d MMM', 'id_ID');
    final end = currentWeekStart.add(const Duration(days: 6));
    final range = '${currentWeekStart.day} – ${fmt.format(end)}';
    final realMonday = PlannerViewModel._getMonday(DateTime.now());
    final isThisWeek =
        DateFormat('yyyy-MM-dd').format(currentWeekStart) ==
        DateFormat('yyyy-MM-dd').format(realMonday);
    return isThisWeek ? 'Minggu ini ($range)' : range;
  }

  PlannerState copyWith({
    List<DailyMealPlanModel>? weeklyPlan,
    DateTime? currentWeekStart,
    bool? isLoading,
    bool? isLoadingCollection,
    List<RecipeModel>? collectionRecipes,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
    String? highlightDateKey,
    MealType? highlightMealType,
    bool clearHighlight = false,
  }) => PlannerState(
    weeklyPlan: weeklyPlan ?? this.weeklyPlan,
    currentWeekStart: currentWeekStart ?? this.currentWeekStart,
    isLoading: isLoading ?? this.isLoading,
    isLoadingCollection: isLoadingCollection ?? this.isLoadingCollection,
    collectionRecipes: collectionRecipes ?? this.collectionRecipes,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    successMessage: clearSuccess
        ? null
        : (successMessage ?? this.successMessage),
    highlightDateKey: clearHighlight
        ? null
        : (highlightDateKey ?? this.highlightDateKey),
    highlightMealType: clearHighlight
        ? null
        : (highlightMealType ?? this.highlightMealType),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ViewModel
// ─────────────────────────────────────────────────────────────────────────────

class PlannerViewModel extends Notifier<PlannerState> {
  static DateTime _getMonday(DateTime d) {
    final wd = d.weekday; // Mon=1 … Sun=7
    return DateTime(d.year, d.month, d.day - (wd - 1));
  }

  static final _fmt = DateFormat('yyyy-MM-dd');

  @override
  PlannerState build() {
    final monday = _getMonday(DateTime.now());
    Future.microtask(() {
      loadCurrentWeek();
      loadCollectionRecipes();
    });
    return PlannerState(currentWeekStart: monday);
  }

  PlannerRepository get _plannerRepo => ref.read(plannerRepositoryProvider);
  RecipeRepository get _recipeRepo =>
      ref.read(recipeRepositoryForPlannerProvider);

  // ── Load Minggu Aktif ─────────────────────────────────────────────────────

  Future<void> loadCurrentWeek() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final start = state.currentWeekStart;
      final end = start.add(const Duration(days: 6));

      // Skeleton 7 hari
      final skeleton = List.generate(7, (i) {
        final day = start.add(Duration(days: i));
        return DailyMealPlanModel(date: _fmt.format(day));
      });

      final data = await _plannerRepo.getWeeklyPlans(
        _fmt.format(start),
        _fmt.format(end),
      );

      final merged = skeleton.map((day) {
        final found = data.where((d) => d.date == day.date).firstOrNull;
        return found ?? day;
      }).toList();

      state = state.copyWith(weeklyPlan: merged, isLoading: false);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat rencana menu',
      );
    }
  }

  // ── Load Koleksi Resep (untuk pilihan di bottom sheet) ───────────────────

  Future<void> loadCollectionRecipes() async {
    state = state.copyWith(isLoadingCollection: true);
    try {
      final userRecipes = await _recipeRepo.getUserRecipes();
      final bookmarked = await _recipeRepo.getBookmarkedRecipes();

      // Gabung + dedup berdasarkan id
      final seen = <String>{};
      final all =
          [...userRecipes, ...bookmarked].where((r) => seen.add(r.id)).toList()
            ..sort((a, b) {
              final at = a.updatedAt ?? a.createdAt;
              final bt = b.updatedAt ?? b.createdAt;
              return bt.compareTo(at);
            });

      state = state.copyWith(
        collectionRecipes: all,
        isLoadingCollection: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingCollection: false);
    }
  }

  // ── Navigasi Minggu ───────────────────────────────────────────────────────

  void goNextWeek() {
    state = state.copyWith(
      currentWeekStart: state.currentWeekStart.add(const Duration(days: 7)),
    );
    loadCurrentWeek();
  }

  void goPrevWeek() {
    state = state.copyWith(
      currentWeekStart: state.currentWeekStart.subtract(
        const Duration(days: 7),
      ),
    );
    loadCurrentWeek();
  }

  // ── Tambah Meal (optimistic) ──────────────────────────────────────────────

  Future<void> addMeal(String date, MealType type, MealItemModel meal) async {
    // Optimistic update
    state = state.copyWith(
      weeklyPlan: state.weeklyPlan.map((day) {
        if (day.date != date) return day;
        return switch (type) {
          MealType.breakfast => day.copyWith(breakfast: meal),
          MealType.lunch => day.copyWith(lunch: meal),
          MealType.dinner => day.copyWith(dinner: meal),
        };
      }).toList(),
    );

    try {
      await _plannerRepo.saveMeal(date, type, meal);
      state = state.copyWith(successMessage: 'Menu berhasil ditambahkan');
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      await loadCurrentWeek(); // Rollback
    } catch (_) {
      state = state.copyWith(errorMessage: 'Gagal menyimpan menu');
      await loadCurrentWeek();
    }
  }

  // ── Hapus Meal (optimistic) ───────────────────────────────────────────────

  Future<void> removeMeal(String date, MealType type) async {
    // Optimistic update — hapus slot tertentu
    state = state.copyWith(
      weeklyPlan: state.weeklyPlan.map((day) {
        if (day.date != date) return day;
        return switch (type) {
          MealType.breakfast => DailyMealPlanModel(
            date: day.date,
            lunch: day.lunch,
            dinner: day.dinner,
          ),
          MealType.lunch => DailyMealPlanModel(
            date: day.date,
            breakfast: day.breakfast,
            dinner: day.dinner,
          ),
          MealType.dinner => DailyMealPlanModel(
            date: day.date,
            breakfast: day.breakfast,
            lunch: day.lunch,
          ),
        };
      }).toList(),
    );

    try {
      await _plannerRepo.removeMeal(date, type);
      state = state.copyWith(successMessage: 'Menu dihapus');
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      await loadCurrentWeek(); // Rollback
    } catch (_) {
      state = state.copyWith(errorMessage: 'Gagal menghapus menu');
      await loadCurrentWeek();
    }
  }

  // ── Lompat ke tanggal tertentu (dari CTA "Lihat Jadwal") ─────────────────

  void jumpToDate(DateTime date, {MealType? highlightMealType}) {
    state = state.copyWith(
      currentWeekStart: _getMonday(date),
      highlightDateKey: _fmt.format(date),
      highlightMealType: highlightMealType,
    );
    loadCurrentWeek();
  }

  void clearHighlight() => state = state.copyWith(clearHighlight: true);

  // ── Helpers ───────────────────────────────────────────────────────────────

  void clearError() => state = state.copyWith(clearError: true);
  void clearSuccess() => state = state.copyWith(clearSuccess: true);
}

final plannerViewModelProvider =
    NotifierProvider<PlannerViewModel, PlannerState>(PlannerViewModel.new);
