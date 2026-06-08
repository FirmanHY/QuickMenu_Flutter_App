import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/app_exception.dart';
import '../../data/models/recipe_model.dart';
import '../../data/repositories/recipe_repository.dart';

// ── Providers ─────────────────────────────────────────────────
final recipeRepositoryProvider = Provider<RecipeRepository>(
  (ref) => RecipeRepository(),
);

// ── State ─────────────────────────────────────────────────────
class RecipeState {
  final List<RecipeModel> publicRecipes;
  final List<RecipeModel> userRecipes;
  final List<RecipeModel> bookmarkedRecipes;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final String selectedCategory;

  const RecipeState({
    this.publicRecipes = const [],
    this.userRecipes = const [],
    this.bookmarkedRecipes = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.selectedCategory = 'Semua',
  });

  // Gabungan custom + bookmarked (untuk Collection screen)
  List<RecipeModel> get allUserRecipes {
    final all = [...userRecipes, ...bookmarkedRecipes];
    all.sort((a, b) {
      final aT = a.updatedAt ?? a.createdAt;
      final bT = b.updatedAt ?? b.createdAt;
      return bT.compareTo(aT);
    });
    return all;
  }

  // Filter untuk Explore screen
  List<RecipeModel> get filteredPublicRecipes {
    var list = publicRecipes;
    if (selectedCategory != 'Semua') {
      list = list
          .where(
            (r) => r.categories.any(
              (c) => c.toLowerCase() == selectedCategory.toLowerCase(),
            ),
          )
          .toList();
    }
    if (searchQuery.isNotEmpty) {
      list = list
          .where(
            (r) => r.title.toLowerCase().contains(searchQuery.toLowerCase()),
          )
          .toList();
    }
    return list;
  }

  // Filter untuk Collection screen
  List<RecipeModel> get filteredUserRecipes {
    var list = allUserRecipes;
    if (selectedCategory != 'Semua') {
      list = list
          .where(
            (r) => r.categories.any(
              (c) => c.toLowerCase() == selectedCategory.toLowerCase(),
            ),
          )
          .toList();
    }
    if (searchQuery.isNotEmpty) {
      list = list
          .where(
            (r) => r.title.toLowerCase().contains(searchQuery.toLowerCase()),
          )
          .toList();
    }
    return list;
  }

  RecipeState copyWith({
    List<RecipeModel>? publicRecipes,
    List<RecipeModel>? userRecipes,
    List<RecipeModel>? bookmarkedRecipes,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    String? selectedCategory,
  }) => RecipeState(
    publicRecipes: publicRecipes ?? this.publicRecipes,
    userRecipes: userRecipes ?? this.userRecipes,
    bookmarkedRecipes: bookmarkedRecipes ?? this.bookmarkedRecipes,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: errorMessage,
    searchQuery: searchQuery ?? this.searchQuery,
    selectedCategory: selectedCategory ?? this.selectedCategory,
  );
}

// ── ViewModel ─────────────────────────────────────────────────
class RecipeViewModel extends Notifier<RecipeState> {
  @override
  RecipeState build() => const RecipeState();

  RecipeRepository get _repo => ref.read(recipeRepositoryProvider);

  Future<void> loadPublicRecipes() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final recipes = await _repo.getPublicRecipes();
      state = state.copyWith(publicRecipes: recipes, isLoading: false);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> loadUserData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final results = await Future.wait([
        _repo.getUserRecipes(),
        _repo.getBookmarkedRecipes(),
      ]);
      state = state.copyWith(
        userRecipes: results[0],
        bookmarkedRecipes: results[1],
        isLoading: false,
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> toggleBookmark(String recipeId, bool currentState) async {
    final newState = !currentState;
    try {
      await _repo.toggleBookmark(recipeId, newState);
      // Update local state optimistis
      final updatedPublic = state.publicRecipes
          .map((r) => r.id == recipeId ? r.copyWith(isBookmarked: newState) : r)
          .toList();
      state = state.copyWith(publicRecipes: updatedPublic);
      await loadUserData(); // refresh bookmarks
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    }
  }

  Future<bool> saveRecipe(RecipeModel recipe) async {
    try {
      await _repo.saveRecipe(recipe);
      await loadUserData();
      return true;
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    }
  }

  Future<bool> updateRecipe(String recipeId, RecipeModel recipe) async {
    try {
      await _repo.updateRecipe(recipeId, recipe);
      await loadUserData();
      return true;
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    }
  }

  Future<bool> deleteRecipe(String recipeId) async {
    try {
      await _repo.deleteRecipe(recipeId);
      await loadUserData();
      return true;
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    }
  }

  void setSearch(String query) => state = state.copyWith(searchQuery: query);

  void setCategory(String category) =>
      state = state.copyWith(selectedCategory: category, searchQuery: '');

  void clearError() => state = state.copyWith(errorMessage: null);
}

final recipeViewModelProvider = NotifierProvider<RecipeViewModel, RecipeState>(
  RecipeViewModel.new,
);
