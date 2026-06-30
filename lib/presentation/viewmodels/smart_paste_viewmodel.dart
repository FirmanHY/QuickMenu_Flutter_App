//   status = input    → user nempel teks mentah
//   status = preview   → hasil auto-detect (SmartPasteParser) ditampilkan di
//                         form yang sama persis dengan Add/Edit Recipe
//                         (title, duration, 2x QuillEditorField), siap diedit

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/quill_html_converter.dart';
import '../../core/utils/smart_paste_parser.dart';
import '../../data/models/recipe_model.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../data/services/cloudinary_service.dart';
import 'add_recipe_viewmodel.dart' show cloudinaryServiceProvider;

// ── Providers ────────────────────────────────────────────────────────────
final _smartPasteRepositoryProvider = Provider<RecipeRepository>(
  (_) => RecipeRepository(),
);

enum SmartPasteStatus { input, preview }

// ── State ────────────────────────────────────────────────────────────────
class SmartPasteState {
  final SmartPasteStatus status;
  final String rawText;
  final String? pasteError;

  final String title;
  final String duration;
  final String ingredientsDelta;
  final String stepsDelta;
  final File? imageFile;

  final String? sourceUrl;
  final String sourcePlatform;

  final bool isSaving;
  final bool success;
  final String? errorMessage;

  final String? titleError;
  final String? durationError;
  final String? ingredientsError;
  final String? stepsError;

  const SmartPasteState({
    this.status = SmartPasteStatus.input,
    this.rawText = '',
    this.pasteError,
    this.title = '',
    this.duration = '',
    this.ingredientsDelta = '',
    this.stepsDelta = '',
    this.imageFile,
    this.sourceUrl,
    this.sourcePlatform = 'Manual',
    this.isSaving = false,
    this.success = false,
    this.errorMessage,
    this.titleError,
    this.durationError,
    this.ingredientsError,
    this.stepsError,
  });

  bool get isPreview => status == SmartPasteStatus.preview;

  SmartPasteState copyWith({
    SmartPasteStatus? status,
    String? rawText,
    String? pasteError,
    bool clearPasteError = false,
    String? title,
    String? duration,
    String? ingredientsDelta,
    String? stepsDelta,
    File? imageFile,
    bool clearImage = false,
    String? sourceUrl,
    String? sourcePlatform,
    bool? isSaving,
    bool? success,
    String? errorMessage,
    bool clearError = false,
    String? titleError,
    bool clearTitleError = false,
    String? durationError,
    bool clearDurationError = false,
    String? ingredientsError,
    bool clearIngredientsError = false,
    String? stepsError,
    bool clearStepsError = false,
  }) => SmartPasteState(
    status: status ?? this.status,
    rawText: rawText ?? this.rawText,
    pasteError: clearPasteError ? null : pasteError ?? this.pasteError,
    title: title ?? this.title,
    duration: duration ?? this.duration,
    ingredientsDelta: ingredientsDelta ?? this.ingredientsDelta,
    stepsDelta: stepsDelta ?? this.stepsDelta,
    imageFile: clearImage ? null : imageFile ?? this.imageFile,
    sourceUrl: sourceUrl ?? this.sourceUrl,
    sourcePlatform: sourcePlatform ?? this.sourcePlatform,
    isSaving: isSaving ?? this.isSaving,
    success: success ?? this.success,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
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
class SmartPasteViewModel extends Notifier<SmartPasteState> {
  @override
  SmartPasteState build() => const SmartPasteState();

  RecipeRepository get _repo => ref.read(_smartPasteRepositoryProvider);
  CloudinaryService get _cloudinary => ref.read(cloudinaryServiceProvider);

  // Dipanggil sekali dari initState layar kalau Smart Paste dibuka dari
  // hasil gagal Import URL (Instagram/TikTok) — biar source badge & link
  // asal tetap ke-tag, persis kayak `originalUrl` di alur Import URL biasa.
  void initSource(String? url) {
    if (url == null || url.isEmpty || state.sourceUrl != null) return;
    state = state.copyWith(
      sourceUrl: url,
      sourcePlatform: SmartPasteParser.detectPlatform(url),
    );
  }

  // ── Tahap 1: input teks ───────────────────────────────────────────────
  void setRawText(String v) =>
      state = state.copyWith(rawText: v, clearPasteError: true);

  void detectAndPreview() {
    if (state.rawText.trim().isEmpty) {
      state = state.copyWith(pasteError: 'Tempel teks resep dulu ya');
      return;
    }

    final result = SmartPasteParser.parse(state.rawText);

    state = state.copyWith(
      status: SmartPasteStatus.preview,
      title: state.title.isEmpty ? result.titleGuess : state.title,
      ingredientsDelta: QuillHtmlConverter.htmlToDelta(result.ingredientsHtml),
      stepsDelta: QuillHtmlConverter.htmlToDelta(result.stepsHtml),
      clearPasteError: true,
    );
  }

  void backToInput() => state = state.copyWith(status: SmartPasteStatus.input);

  // ── Tahap 2: edit hasil deteksi (sebelum simpan) ─────────────────────────
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

  Future<bool> submit() async {
    if (!_validate()) return false;

    state = state.copyWith(isSaving: true, clearError: true);
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
        categories: const [],
        ingredients: QuillHtmlConverter.deltaToHtml(state.ingredientsDelta),
        steps: QuillHtmlConverter.deltaToHtml(state.stepsDelta),
        source: state.sourcePlatform,
        originalUrl: state.sourceUrl,
        imagePublicId: imagePublicId,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await _repo.saveRecipe(recipe);
      state = state.copyWith(isSaving: false, success: true);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Gagal menyimpan resep: $e',
      );
      return false;
    }
  }

  void reset() => state = const SmartPasteState();
}

final smartPasteViewModelProvider =
    NotifierProvider<SmartPasteViewModel, SmartPasteState>(
      SmartPasteViewModel.new,
    );
