import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/app_exception.dart';
import '../../data/models/recipe_model.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../data/services/scraper_service.dart';

// ── Providers ─────────────────────────────────────────────────
final _scraperServiceProvider = Provider<ScraperService>(
  (_) => ScraperService(),
);

final _importRecipeRepositoryProvider = Provider<RecipeRepository>(
  (_) => RecipeRepository(),
);

// ── State ─────────────────────────────────────────────────────
enum ImportStatus { idle, loading, success, error, saving }

class ImportPreviewState {
  final ImportStatus status;
  final String? errorMessage;
  final ScrapedRecipe? scrapedRecipe;

  // Editable fields (user bisa edit setelah preview)
  final String title;
  final String duration;
  final List<String> selectedCategories;
  final String? titleError;
  final String? durationError;

  const ImportPreviewState({
    this.status = ImportStatus.idle,
    this.errorMessage,
    this.scrapedRecipe,
    this.title = '',
    this.duration = '',
    this.selectedCategories = const [],
    this.titleError,
    this.durationError,
  });

  bool get isLoading => status == ImportStatus.loading;
  bool get isSaving => status == ImportStatus.saving;
  bool get hasData => scrapedRecipe != null;

  ImportPreviewState copyWith({
    ImportStatus? status,
    String? errorMessage,
    bool clearError = false,
    ScrapedRecipe? scrapedRecipe,
    String? title,
    String? duration,
    List<String>? selectedCategories,
    String? titleError,
    bool clearTitleError = false,
    String? durationError,
    bool clearDurationError = false,
  }) => ImportPreviewState(
    status: status ?? this.status,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    scrapedRecipe: scrapedRecipe ?? this.scrapedRecipe,
    title: title ?? this.title,
    duration: duration ?? this.duration,
    selectedCategories: selectedCategories ?? this.selectedCategories,
    titleError: clearTitleError ? null : titleError ?? this.titleError,
    durationError: clearDurationError
        ? null
        : durationError ?? this.durationError,
  );
}

// ── ViewModel ─────────────────────────────────────────────────
class ImportPreviewViewModel extends Notifier<ImportPreviewState> {
  @override
  ImportPreviewState build() => const ImportPreviewState();

  ScraperService get _scraper => ref.read(_scraperServiceProvider);
  RecipeRepository get _repo => ref.read(_importRecipeRepositoryProvider);

  // ── Scrape from URL ───────────────────────────────────────
  Future<void> scrapeFromUrl(String url) async {
    if (url.trim().isEmpty) return;

    state = state.copyWith(status: ImportStatus.loading, clearError: true);

    try {
      final scraped = await _scraper.scrapeFromUrl(url.trim());

      state = state.copyWith(
        status: ImportStatus.success,
        scrapedRecipe: scraped,
        title: scraped.title,
        duration: scraped.duration,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        status: ImportStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: ImportStatus.error,
        errorMessage: 'Gagal mengambil resep: $e',
      );
    }
  }

  // ── Field Setters ─────────────────────────────────────────
  void setTitle(String v) =>
      state = state.copyWith(title: v, clearTitleError: true);

  void setDuration(String v) =>
      state = state.copyWith(duration: v, clearDurationError: true);

  void toggleCategory(String category) {
    final current = List<String>.from(state.selectedCategories);
    current.contains(category)
        ? current.remove(category)
        : current.add(category);
    state = state.copyWith(selectedCategories: current);
  }

  // ── Validation ────────────────────────────────────────────
  bool _validate() {
    bool valid = true;

    if (state.title.trim().isEmpty) {
      state = state.copyWith(titleError: 'Judul tidak boleh kosong');
      valid = false;
    }

    if (state.duration.trim().isEmpty) {
      state = state.copyWith(durationError: 'Durasi tidak boleh kosong');
      valid = false;
    } else if (int.tryParse(state.duration.trim()) == null) {
      state = state.copyWith(durationError: 'Masukkan angka yang valid');
      valid = false;
    }

    return valid;
  }

  // ── Save Recipe ───────────────────────────────────────────
  Future<bool> saveRecipe() async {
    if (!_validate()) return false;
    if (state.scrapedRecipe == null) return false;

    state = state.copyWith(status: ImportStatus.saving, clearError: true);

    try {
      final scraped = state.scrapedRecipe!;
      final recipe = RecipeModel(
        id: '',
        title: state.title.trim(),
        imageUrl: scraped.imageUrl,
        duration: state.duration.trim(),
        categories: state.selectedCategories,
        ingredients: scraped.ingredients,
        steps: scraped.steps,
        source: scraped.source,
        originalUrl: scraped.originalUrl,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await _repo.saveRecipe(recipe);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        status: ImportStatus.success, // kembali ke preview state
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: ImportStatus.success,
        errorMessage: 'Gagal menyimpan resep: $e',
      );
      return false;
    }
  }

  // ── Reset ─────────────────────────────────────────────────
  void reset() => state = const ImportPreviewState();
}

final importPreviewViewModelProvider =
    NotifierProvider<ImportPreviewViewModel, ImportPreviewState>(
      ImportPreviewViewModel.new,
    );
