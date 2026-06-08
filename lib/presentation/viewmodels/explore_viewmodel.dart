//
// ViewModel khusus untuk Explore Screen (MVVM pattern).
// Bertanggung jawab atas:
//  - Load public QuickMenu recipes dari Firebase RTDB
//  - Load kategori dari Firebase RTDB
//  - Filter berdasarkan search query & kategori
//  - Toggle bookmark (optimistic update)
//  - Pull-to-refresh

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/app_exception.dart';
import '../../data/models/category_model.dart';
import '../../data/models/recipe_model.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../data/repositories/category_repository.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class ExploreState {
  final List<RecipeModel> allRecipes;
  final List<CategoryModel> categories;
  final String searchQuery;
  final String selectedCategory; // 'Semua' = no filter
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;

  const ExploreState({
    this.allRecipes = const [],
    this.categories = const [],
    this.searchQuery = '',
    this.selectedCategory = 'Semua',
    this.isLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
  });

  // ── Computed filtered list ────────────────────────────────────────────────
  List<RecipeModel> get filteredRecipes {
    var list = allRecipes;

    // Filter by category
    if (selectedCategory != 'Semua') {
      list = list
          .where(
            (r) => r.categories.any(
              (c) => c.toLowerCase() == selectedCategory.toLowerCase(),
            ),
          )
          .toList();
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list
          .where(
            (r) =>
                r.title.toLowerCase().contains(q) ||
                r.categories.any((c) => c.toLowerCase().contains(q)),
          )
          .toList();
    }

    return list;
  }

  bool get isEmpty => filteredRecipes.isEmpty;
  bool get hasError => errorMessage != null;

  ExploreState copyWith({
    List<RecipeModel>? allRecipes,
    List<CategoryModel>? categories,
    String? searchQuery,
    String? selectedCategory,
    bool? isLoading,
    bool? isRefreshing,
    String? errorMessage,
    bool clearError = false,
  }) => ExploreState(
    allRecipes: allRecipes ?? this.allRecipes,
    categories: categories ?? this.categories,
    searchQuery: searchQuery ?? this.searchQuery,
    selectedCategory: selectedCategory ?? this.selectedCategory,
    isLoading: isLoading ?? this.isLoading,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}

// ─── Providers ────────────────────────────────────────────────────────────────

final _exploreRecipeRepoProvider = Provider<RecipeRepository>(
  (_) => RecipeRepository(),
);

final _exploreCategoryRepoProvider = Provider<CategoryRepository>(
  (_) => CategoryRepository(),
);

final exploreViewModelProvider =
    NotifierProvider<ExploreViewModel, ExploreState>(ExploreViewModel.new);

// ─── ViewModel ────────────────────────────────────────────────────────────────

class ExploreViewModel extends Notifier<ExploreState> {
  @override
  ExploreState build() => const ExploreState();

  RecipeRepository get _recipeRepo => ref.read(_exploreRecipeRepoProvider);
  CategoryRepository get _categoryRepo =>
      ref.read(_exploreCategoryRepoProvider);

  // ── Load initial data ─────────────────────────────────────────────────────

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final results = await Future.wait([
        _recipeRepo.getPublicRecipes(),
        _categoryRepo.getDefaultCategories(),
      ]);

      print('Results: $results');

      state = state.copyWith(
        allRecipes: results[0] as List<RecipeModel>,
        categories: results[1] as List<CategoryModel>,
        isLoading: false,
      );
    } on AppException catch (e) {
      print('AppException: ${e.message}');
      print('StackTrace: $e');

      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e, stackTrace) {
      print('Error: $e');
      print('StackTrace: $stackTrace');

      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat data. Coba lagi.',
      );
    }
  }

  // ── Pull-to-refresh ───────────────────────────────────────────────────────

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, clearError: true);
    try {
      final results = await Future.wait([
        _recipeRepo.getPublicRecipes(),
        _categoryRepo.getDefaultCategories(),
      ]);
      state = state.copyWith(
        allRecipes: results[0] as List<RecipeModel>,
        categories: results[1] as List<CategoryModel>,
        isRefreshing: false,
      );
    } on AppException catch (e) {
      state = state.copyWith(isRefreshing: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: 'Gagal refresh. Coba lagi.',
      );
    }
  }

  // ── Search ────────────────────────────────────────────────────────────────

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query, clearError: true);
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '', clearError: true);
  }

  // ── Category filter ───────────────────────────────────────────────────────

  void selectCategory(String category) {
    state = state.copyWith(selectedCategory: category, clearError: true);
  }

  // ── Bookmark toggle (optimistic update) ──────────────────────────────────

  Future<void> toggleBookmark(String recipeId, bool currentState) async {
    final newBookmarked = !currentState;

    // Optimistic update
    state = state.copyWith(
      allRecipes: state.allRecipes
          .map(
            (r) =>
                r.id == recipeId ? r.copyWith(isBookmarked: newBookmarked) : r,
          )
          .toList(),
    );

    try {
      await _recipeRepo.toggleBookmark(recipeId, newBookmarked);
    } on AppException catch (e) {
      // Revert on failure
      state = state.copyWith(
        allRecipes: state.allRecipes
            .map(
              (r) =>
                  r.id == recipeId ? r.copyWith(isBookmarked: currentState) : r,
            )
            .toList(),
        errorMessage: e.message,
      );
    }
  }
}
