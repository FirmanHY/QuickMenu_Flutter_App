import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/app_exception.dart';
import '../../data/models/meal_plan_model.dart';
import '../../data/models/recipe_model.dart';
import '../../data/repositories/home_repository.dart';

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepository(),
);

// ── State ─────────────────────────────────────────────────────
class HomeState {
  final String userName;
  final DailyMealPlanModel? todayPlan;
  final List<RecipeModel> healthyRecipes;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;

  const HomeState({
    this.userName = 'Pengguna',
    this.todayPlan,
    this.healthyRecipes = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
  });

  HomeState copyWith({
    String? userName,
    DailyMealPlanModel? todayPlan,
    bool clearTodayPlan = false,
    List<RecipeModel>? healthyRecipes,
    bool? isLoading,
    bool? isRefreshing,
    String? errorMessage,
    bool clearError = false,
  }) => HomeState(
    userName: userName ?? this.userName,
    todayPlan: clearTodayPlan ? null : todayPlan ?? this.todayPlan,
    healthyRecipes: healthyRecipes ?? this.healthyRecipes,
    isLoading: isLoading ?? this.isLoading,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}

// ── ViewModel ─────────────────────────────────────────────────
class HomeViewModel extends Notifier<HomeState> {
  @override
  HomeState build() => const HomeState();

  HomeRepository get _repo => ref.read(homeRepositoryProvider);

  Future<void> loadHomeData({bool isRefresh = false}) async {
    if (isRefresh) {
      state = state.copyWith(isRefreshing: true, clearError: true);
    } else {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      // Load semua paralel
      final results = await Future.wait([
        _repo.getTodayMealPlan(),
        _repo.getHealthyRecipes(),
        _repo.getUserFullName(),
      ]);

      final todayPlan = results[0] as DailyMealPlanModel?;
      final recipes = results[1] as List<RecipeModel>;
      final fullName = results[2] as String?;

      // Fallback ke displayName dari Firebase Auth
      final authName = ref
          .read(homeRepositoryProvider)
          .toString(); // just trigger read
      final user = FirebaseAuth.instance.currentUser;
      final name = fullName ?? user?.displayName ?? 'Pengguna';

      state = state.copyWith(
        userName: name,
        todayPlan: todayPlan,
        clearTodayPlan: todayPlan == null,
        healthyRecipes: recipes,
        isLoading: false,
        isRefreshing: false,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: 'Gagal memuat data',
      );
    }
  }

  Future<void> toggleBookmark(String recipeId, bool current) async {
    final newVal = !current;

    // Optimistic update
    final updated = state.healthyRecipes
        .map((r) => r.id == recipeId ? r.copyWith(isBookmarked: newVal) : r)
        .toList();
    state = state.copyWith(healthyRecipes: updated);

    try {
      await _repo.toggleBookmark(recipeId, newVal);
    } catch (_) {
      // Rollback
      final rolled = state.healthyRecipes
          .map((r) => r.id == recipeId ? r.copyWith(isBookmarked: current) : r)
          .toList();
      state = state.copyWith(
        healthyRecipes: rolled,
        errorMessage: 'Gagal mengubah bookmark',
      );
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final homeViewModelProvider = NotifierProvider<HomeViewModel, HomeState>(
  HomeViewModel.new,
);
