import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/quill_html_converter.dart';
import '../../data/models/recipe_model.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../data/services/cloudinary_service.dart';
import 'add_recipe_viewmodel.dart' show cloudinaryServiceProvider;

// ── Providers ────────────────────────────────────────────────────────────
final _editRecipeRepositoryProvider = Provider<RecipeRepository>(
  (_) => RecipeRepository(),
);

// ── State ────────────────────────────────────────────────────────────────
class EditRecipeState {
  final bool isLoading; // loading resep awal
  final bool isSaving; // proses update
  final bool notFound;
  final String? errorMessage;
  final bool success;

  final RecipeModel? originalRecipe;

  final String title;
  final String duration;
  final String ingredientsDelta;
  final String stepsDelta;

  final String? currentImageUrl; // gambar lama (network)
  final File? newImageFile; // gambar baru yang dipilih
  final bool isImageRemoved; // user menekan tombol hapus gambar

  final String? titleError;
  final String? durationError;
  final String? ingredientsError;
  final String? stepsError;

  const EditRecipeState({
    this.isLoading = true,
    this.isSaving = false,
    this.notFound = false,
    this.errorMessage,
    this.success = false,
    this.originalRecipe,
    this.title = '',
    this.duration = '',
    this.ingredientsDelta = '',
    this.stepsDelta = '',
    this.currentImageUrl,
    this.newImageFile,
    this.isImageRemoved = false,
    this.titleError,
    this.durationError,
    this.ingredientsError,
    this.stepsError,
  });

  bool get hasNewImage => newImageFile != null;
  bool get hasAnyImage =>
      newImageFile != null || (!isImageRemoved && currentImageUrl != null);

  EditRecipeState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? notFound,
    String? errorMessage,
    bool clearError = false,
    bool? success,
    RecipeModel? originalRecipe,
    String? title,
    String? duration,
    String? ingredientsDelta,
    String? stepsDelta,
    String? currentImageUrl,
    bool clearCurrentImageUrl = false,
    File? newImageFile,
    bool clearNewImageFile = false,
    bool? isImageRemoved,
    String? titleError,
    bool clearTitleError = false,
    String? durationError,
    bool clearDurationError = false,
    String? ingredientsError,
    bool clearIngredientsError = false,
    String? stepsError,
    bool clearStepsError = false,
  }) => EditRecipeState(
    isLoading: isLoading ?? this.isLoading,
    isSaving: isSaving ?? this.isSaving,
    notFound: notFound ?? this.notFound,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    success: success ?? this.success,
    originalRecipe: originalRecipe ?? this.originalRecipe,
    title: title ?? this.title,
    duration: duration ?? this.duration,
    ingredientsDelta: ingredientsDelta ?? this.ingredientsDelta,
    stepsDelta: stepsDelta ?? this.stepsDelta,
    currentImageUrl: clearCurrentImageUrl
        ? null
        : currentImageUrl ?? this.currentImageUrl,
    newImageFile: clearNewImageFile ? null : newImageFile ?? this.newImageFile,
    isImageRemoved: isImageRemoved ?? this.isImageRemoved,
    titleError: clearTitleError ? null : titleError ?? this.titleError,
    durationError: clearDurationError
        ? null
        : durationError ?? this.durationError,
    ingredientsError: clearIngredientsError
        ? null
        : ingredientsError ?? this.ingredientsError,
    stepsError: clearStepsError ? null : stepsError ?? this.stepsError,
  );
}

// ── ViewModel ────────────────────────────────────────────────────────────
class EditRecipeViewModel extends Notifier<EditRecipeState> {
  final String recipeId;

  EditRecipeViewModel(this.recipeId);

  @override
  EditRecipeState build() {
    Future.microtask(_loadRecipe);
    return const EditRecipeState(isLoading: true);
  }

  RecipeRepository get _repo => ref.read(_editRecipeRepositoryProvider);
  CloudinaryService get _cloudinary => ref.read(cloudinaryServiceProvider);

  // ── Load data resep yang akan diedit ────────────────────────────────────
  Future<void> _loadRecipe() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final recipe = await _repo.getRecipeById(recipeId);
      if (recipe == null) {
        state = state.copyWith(isLoading: false, notFound: true);
        return;
      }

      state = state.copyWith(
        isLoading: false,
        originalRecipe: recipe,
        title: recipe.title,
        duration: recipe.duration
            .replaceAll(RegExp(r'min', caseSensitive: false), '')
            .trim(),
        ingredientsDelta: QuillHtmlConverter.htmlToDelta(recipe.ingredients),
        stepsDelta: QuillHtmlConverter.htmlToDelta(recipe.steps),
        currentImageUrl: recipe.imageUrl,
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat data resep',
      );
    }
  }

  // ── Field setters ────────────────────────────────────────────────────────
  void setTitle(String v) =>
      state = state.copyWith(title: v, clearTitleError: true);

  void setDuration(String v) =>
      state = state.copyWith(duration: v, clearDurationError: true);

  void setIngredientsDelta(String json) => state = state.copyWith(
    ingredientsDelta: json,
    clearIngredientsError: true,
  );

  void setStepsDelta(String json) =>
      state = state.copyWith(stepsDelta: json, clearStepsError: true);

  void setImage(File file) =>
      state = state.copyWith(newImageFile: file, isImageRemoved: false);

  void removeImage() => state = state.copyWith(
    clearNewImageFile: true,
    clearCurrentImageUrl: true,
    isImageRemoved: true,
  );

  // ── Validasi  ─────────────
  bool _validate() {
    final titleErr = state.title.trim().isEmpty
        ? 'Judul resep wajib diisi'
        : null;
    final durationErr = state.duration.trim().isEmpty
        ? 'Durasi wajib diisi'
        : int.tryParse(state.duration.trim()) == null
        ? 'Durasi harus berupa angka'
        : null;
    final ingErr =
        QuillHtmlConverter.deltaToPlainText(state.ingredientsDelta).isEmpty
        ? 'Bahan-bahan tidak boleh kosong'
        : null;
    final stepsErr =
        QuillHtmlConverter.deltaToPlainText(state.stepsDelta).isEmpty
        ? 'Langkah-langkah tidak boleh kosong'
        : null;

    state = state.copyWith(
      titleError: titleErr,
      durationError: durationErr,
      ingredientsError: ingErr,
      stepsError: stepsErr,
    );

    return titleErr == null &&
        durationErr == null &&
        ingErr == null &&
        stepsErr == null;
  }

  // ── Submit update ────────────────────────────────────────────────────────
  Future<bool> submit() async {
    final original = state.originalRecipe;
    if (original == null) return false;
    if (!_validate()) return false;

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      String? imageUrl = original.imageUrl;
      String? imagePublicId = original.imagePublicId;

      if (state.newImageFile != null) {
        final result = await _cloudinary.uploadImage(state.newImageFile!);
        imageUrl = result.secureUrl;
        imagePublicId = result.publicId;
      } else if (state.isImageRemoved) {
        imageUrl = null;
        imagePublicId = null;
      }

      // Dibangun manual (bukan copyWith) karena RecipeModel.copyWith tidak
      // bisa mengeset field nullable jadi null — dibutuhkan untuk kasus
      // "hapus gambar".
      final updated = RecipeModel(
        id: original.id,
        title: state.title.trim(),
        imageUrl: imageUrl,
        duration: state.duration.trim(),
        categories: original.categories,
        ingredients: QuillHtmlConverter.deltaToHtml(state.ingredientsDelta),
        steps: QuillHtmlConverter.deltaToHtml(state.stepsDelta),
        source: original.source,
        originalUrl: original.originalUrl,
        userId: original.userId,
        isBookmarked: original.isBookmarked,
        createdAt: original.createdAt,
        imagePublicId: imagePublicId,
      );

      await _repo.updateRecipe(recipeId, updated);
      state = state.copyWith(isSaving: false, success: true);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Gagal mengupdate resep: $e',
      );
      return false;
    }
  }
}

final editRecipeViewModelProvider =
    NotifierProvider.family<EditRecipeViewModel, EditRecipeState, String>(
      EditRecipeViewModel.new,
    );
