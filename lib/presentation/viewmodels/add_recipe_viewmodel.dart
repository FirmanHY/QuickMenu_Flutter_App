import 'dart:convert';
import 'dart:io';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/app_exception.dart';
import '../../data/models/recipe_model.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../data/services/cloudinary_service.dart';

final cloudinaryServiceProvider = Provider<CloudinaryService>(
  (_) => CloudinaryService(),
);

// ← Define sendiri di sini, tidak import dari recipe_viewmodel
// supaya tidak ada circular dependency
final _addRecipeRepositoryProvider = Provider<RecipeRepository>(
  (_) => RecipeRepository(),
);

// ── State ─────────────────────────────────────────────────────
class AddRecipeState {
  final bool isLoading;
  final String? errorMessage;
  final bool success;
  final String title;
  final String duration;
  final String ingredientsDelta;
  final String stepsDelta;
  final File? imageFile;
  final List<String> selectedCategories;
  final String? titleError;
  final String? durationError;
  final String? ingredientsError;
  final String? stepsError;

  const AddRecipeState({
    this.isLoading = false,
    this.errorMessage,
    this.success = false,
    this.title = '',
    this.duration = '',
    this.ingredientsDelta = '',
    this.stepsDelta = '',
    this.imageFile,
    this.selectedCategories = const [],
    this.titleError,
    this.durationError,
    this.ingredientsError,
    this.stepsError,
  });

  bool get hasImage => imageFile != null;

  AddRecipeState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? success,
    String? title,
    String? duration,
    String? ingredientsDelta,
    String? stepsDelta,
    File? imageFile,
    bool clearImage = false,
    List<String>? selectedCategories,
    String? titleError,
    bool clearTitleError = false,
    String? durationError,
    bool clearDurationError = false,
    String? ingredientsError,
    bool clearIngredientsError = false,
    String? stepsError,
    bool clearStepsError = false,
  }) => AddRecipeState(
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    success: success ?? this.success,
    title: title ?? this.title,
    duration: duration ?? this.duration,
    ingredientsDelta: ingredientsDelta ?? this.ingredientsDelta,
    stepsDelta: stepsDelta ?? this.stepsDelta,
    imageFile: clearImage ? null : imageFile ?? this.imageFile,
    selectedCategories: selectedCategories ?? this.selectedCategories,
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

// ── ViewModel ─────────────────────────────────────────────────
class AddRecipeViewModel extends Notifier<AddRecipeState> {
  @override
  AddRecipeState build() => const AddRecipeState();

  RecipeRepository get _repo =>
      ref.read(_addRecipeRepositoryProvider); // ← pakai provider lokal
  CloudinaryService get _cloudinary => ref.read(cloudinaryServiceProvider);

  // ── Field setters ─────────────────────────────────────────
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

  void setImage(File file) => state = state.copyWith(imageFile: file);
  void removeImage() => state = state.copyWith(clearImage: true);

  void toggleCategory(String category) {
    final current = List<String>.from(state.selectedCategories);
    current.contains(category)
        ? current.remove(category)
        : current.add(category);
    state = state.copyWith(selectedCategories: current);
  }

  // ── Delta JSON → HTML ─────────────────────────────────────
  String _deltaToHtml(String deltaJson) {
    if (deltaJson.isEmpty) return '';
    try {
      final ops = Document.fromJson(
        jsonDecode(deltaJson) as List,
      ).toDelta().toList();

      final buffer = StringBuffer();

      final lineBuffer = StringBuffer();
      bool inBullet = false;
      bool inOrdered = false;

      void closeLists() {
        if (inBullet) {
          buffer.write('</ul>');
          inBullet = false;
        }
        if (inOrdered) {
          buffer.write('</ol>');
          inOrdered = false;
        }
      }

      void flushLine(Map<String, dynamic> lineAttrs) {
        final isBullet = lineAttrs['list'] == 'bullet';
        final isOrdered = lineAttrs['list'] == 'ordered';
        final lineContent = lineBuffer.toString();
        lineBuffer.clear();

        if (isBullet) {
          if (inOrdered) {
            buffer.write('</ol>');
            inOrdered = false;
          }
          if (!inBullet) {
            buffer.write('<ul>');
            inBullet = true;
          }
          buffer.write('<li>$lineContent</li>');
        } else if (isOrdered) {
          if (inBullet) {
            buffer.write('</ul>');
            inBullet = false;
          }
          if (!inOrdered) {
            buffer.write('<ol>');
            inOrdered = true;
          }
          buffer.write('<li>$lineContent</li>');
        } else {
          // Baris biasa (bukan list)
          closeLists();
          if (lineContent.isNotEmpty) {
            buffer.write('<p>$lineContent</p>');
          } else {
            buffer.write('<br>');
          }
        }
      }

      for (final op in ops) {
        if (!op.isInsert) continue;

        final text = op.data.toString();
        final attrs = Map<String, dynamic>.from(op.attributes ?? {});

        if (text == '\n') {
          // Newline = akhir dari satu line, flush dengan format line ini
          flushLine(attrs);
        } else {
          // Teks biasa — wrap inline formatting dulu, taruh di lineBuffer
          var content = text;
          if (attrs['bold'] == true) content = '<b>$content</b>';
          if (attrs['italic'] == true) content = '<i>$content</i>';
          if (attrs['underline'] == true) content = '<u>$content</u>';
          lineBuffer.write(content);
        }
      }

      // Flush sisa konten yang belum diakhiri newline
      if (lineBuffer.isNotEmpty) {
        flushLine({});
      }

      closeLists();
      return buffer.toString();
    } catch (e) {
      return deltaJson;
    }
  }

  String _deltaToPlainText(String deltaJson) {
    if (deltaJson.isEmpty) return '';
    try {
      final doc = Document.fromJson(jsonDecode(deltaJson) as List);
      return doc.toPlainText().trim();
    } catch (_) {
      return deltaJson;
    }
  }

  // ── Validation ────────────────────────────────────────────
  bool _validate() {
    final titleErr = state.title.trim().isEmpty
        ? 'Judul resep wajib diisi'
        : null;
    final durationErr = state.duration.trim().isEmpty
        ? 'Durasi wajib diisi'
        : int.tryParse(state.duration.trim()) == null
        ? 'Durasi harus berupa angka'
        : null;
    final ingErr = _deltaToPlainText(state.ingredientsDelta).isEmpty
        ? 'Bahan-bahan tidak boleh kosong'
        : null;
    final stepsErr = _deltaToPlainText(state.stepsDelta).isEmpty
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

  // ── Submit ────────────────────────────────────────────────
  Future<bool> submit() async {
    if (!_validate()) return false;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      String? imageUrl;
      String? imagePublicId;

      if (state.imageFile != null) {
        final result = await _cloudinary.uploadImage(state.imageFile!);
        imageUrl = result.secureUrl;
        imagePublicId = result.publicId;
      }

      final recipe = RecipeModel(
        id: '',
        title: state.title.trim(),
        imageUrl: imageUrl,
        duration: state.duration.trim(),
        categories: state.selectedCategories,
        ingredients: _deltaToHtml(state.ingredientsDelta),
        steps: _deltaToHtml(state.stepsDelta),
        source: 'Manual',
        imagePublicId: imagePublicId,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await _repo.saveRecipe(recipe);
      state = state.copyWith(isLoading: false, success: true);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal menyimpan resep: $e',
      );
      return false;
    }
  }

  void reset() => state = const AddRecipeState();
}

final addRecipeViewModelProvider =
    NotifierProvider<AddRecipeViewModel, AddRecipeState>(
      AddRecipeViewModel.new,
    );
