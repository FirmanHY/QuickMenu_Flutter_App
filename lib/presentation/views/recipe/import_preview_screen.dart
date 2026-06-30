import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_router.dart';
import '../../../core/utils/smart_paste_parser.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../../viewmodels/import_preview_viewmodel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen entry-point — menerima URL dari argument navigasi
// ─────────────────────────────────────────────────────────────────────────────
class ImportPreviewScreen extends ConsumerStatefulWidget {
  final String url;
  const ImportPreviewScreen({super.key, required this.url});

  @override
  ConsumerState<ImportPreviewScreen> createState() =>
      _ImportPreviewScreenState();
}

class _ImportPreviewScreenState extends ConsumerState<ImportPreviewScreen> {
  final _titleCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Trigger scrape setelah frame pertama selesai
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(importPreviewViewModelProvider.notifier)
          .scrapeFromUrl(widget.url);
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _durationCtrl.dispose();
    // Reset ViewModel saat screen ditutup
    ref.read(importPreviewViewModelProvider.notifier).reset();
    super.dispose();
  }

  // Sync controller text dari state (hanya sekali setelah data masuk)
  void _syncControllers(ImportPreviewState state) {
    if (!_initialized && state.hasData) {
      _titleCtrl.text = state.title;
      _durationCtrl.text = state.duration;
      _initialized = true;
    }
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    final success = await ref
        .read(importPreviewViewModelProvider.notifier)
        .saveRecipe();
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resep berhasil disimpan! 🎉'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(importPreviewViewModelProvider);

    // Sync controller text
    _syncControllers(state);

    // Listen untuk error message
    ref.listen(importPreviewViewModelProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Preview Resep'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(ImportPreviewState state) {
    // ── Loading state ────────────────────────────────────────
    if (state.isLoading) {
      return const _LoadingView();
    }

    // ── Error state ──────────────────────────────────────────
    if (state.status == ImportStatus.error && !state.hasData) {
      final platform = SmartPasteParser.detectPlatform(widget.url);
      final isUnsupported = platform == 'Instagram' || platform == 'TikTok';
      return _ErrorView(
        message: state.errorMessage ?? 'Terjadi kesalahan',
        url: widget.url,
        onRetry: () => ref
            .read(importPreviewViewModelProvider.notifier)
            .scrapeFromUrl(widget.url),
        onSmartPaste: isUnsupported
            ? () => context.pushReplacement(
                AppRoutes.smartPaste,
                extra: widget.url,
              )
            : null,
      );
    }

    // ── Preview state ────────────────────────────────────────
    if (state.hasData) {
      return _PreviewContent(
        state: state,
        titleCtrl: _titleCtrl,
        durationCtrl: _durationCtrl,
        onSave: _handleSave,
      );
    }

    // ── Idle state ───────────────────────────────────────────
    return const SizedBox.shrink();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading View
// ─────────────────────────────────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: AppDimensions.lg),
          Text(
            'Mengambil resep...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            'Ini mungkin butuh beberapa detik',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error View
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final String url;
  final VoidCallback onRetry;
  final VoidCallback? onSmartPaste; // ← baru

  const _ErrorView({
    required this.message,
    required this.url,
    required this.onRetry,
    this.onSmartPaste,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenHorizontal,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.link_off_rounded,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppDimensions.lg),
            Text(
              'Gagal Mengambil Resep',
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.xs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md,
                vertical: AppDimensions.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                url,
                style: AppTextStyles.caption.copyWith(color: AppColors.gray400),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppDimensions.xl),
            AppButton(
              title: 'Coba Lagi',
              onPressed: onRetry,
              type: AppButtonType.outline,
            ),
            if (onSmartPaste != null) ...[
              const SizedBox(height: AppDimensions.sm),
              AppButton(title: 'Pakai Smart Paste', onPressed: onSmartPaste!),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Preview Content — main content setelah scrape berhasil
// ─────────────────────────────────────────────────────────────────────────────
class _PreviewContent extends ConsumerWidget {
  final ImportPreviewState state;
  final TextEditingController titleCtrl;
  final TextEditingController durationCtrl;
  final VoidCallback onSave;

  const _PreviewContent({
    required this.state,
    required this.titleCtrl,
    required this.durationCtrl,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scraped = state.scrapedRecipe!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenHorizontal,
        vertical: AppDimensions.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Source Badge ──────────────────────────────────
          _SourceBadge(source: scraped.source),
          const SizedBox(height: AppDimensions.lg),

          // ── Image Preview ─────────────────────────────────
          if (scraped.imageUrl != null) ...[
            _RecipeImagePreview(imageUrl: scraped.imageUrl!),
            const SizedBox(height: AppDimensions.xl),
          ],

          // ── Section: Edit Info ────────────────────────────
          _SectionLabel(label: 'Informasi Resep'),
          const SizedBox(height: AppDimensions.md),

          AppInput(
            label: 'Judul Resep',
            placeholder: 'Misal: Nasi Goreng Spesial',
            controller: titleCtrl,
            errorText: state.titleError,
            onChanged: (v) =>
                ref.read(importPreviewViewModelProvider.notifier).setTitle(v),
          ),

          AppInput(
            label: 'Durasi (menit)',
            placeholder: 'Misal: 30',
            controller: durationCtrl,
            keyboardType: TextInputType.number,
            errorText: state.durationError,
            onChanged: (v) => ref
                .read(importPreviewViewModelProvider.notifier)
                .setDuration(v),
          ),

          // ── Kategori ──────────────────────────────────────
          _CategorySelector(
            selected: state.selectedCategories,
            onToggle: (cat) => ref
                .read(importPreviewViewModelProvider.notifier)
                .toggleCategory(cat),
          ),

          const SizedBox(height: AppDimensions.xl),

          // ── Section: Bahan-bahan Preview ──────────────────
          _SectionLabel(label: 'Bahan-bahan'),
          const SizedBox(height: AppDimensions.sm),
          _HtmlPreviewCard(htmlContent: scraped.ingredients),

          const SizedBox(height: AppDimensions.lg),

          // ── Section: Langkah-langkah Preview ─────────────
          _SectionLabel(label: 'Langkah-langkah'),
          const SizedBox(height: AppDimensions.sm),
          _HtmlPreviewCard(htmlContent: scraped.steps),

          const SizedBox(height: AppDimensions.xl),

          // ── Source URL ────────────────────────────────────
          _OriginalUrlRow(url: scraped.originalUrl),

          const SizedBox(height: AppDimensions.lg),

          // ── Save Button ───────────────────────────────────
          AppButton(
            title: 'Simpan Resep',
            onPressed: onSave,
            isLoading: state.isSaving,
          ),

          const SizedBox(height: AppDimensions.xxl),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SourceBadge extends StatelessWidget {
  final String source;
  const _SourceBadge({required this.source});

  Color get _color {
    switch (source.toLowerCase()) {
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'instagram':
        return const Color(0xFFE1306C);
      case 'tiktok':
        return const Color(0xFF010101);
      default:
        return AppColors.primary;
    }
  }

  IconData get _icon {
    switch (source.toLowerCase()) {
      case 'youtube':
        return Icons.play_circle_outline_rounded;
      case 'instagram':
        return Icons.camera_alt_outlined;
      case 'tiktok':
        return Icons.music_note_rounded;
      default:
        return Icons.language_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: _color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_icon, size: 14, color: _color),
              const SizedBox(width: 4),
              Text(
                'Import dari $source',
                style: AppTextStyles.caption.copyWith(
                  color: _color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecipeImagePreview extends StatelessWidget {
  final String imageUrl;
  const _RecipeImagePreview({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (_, _) => Container(
            color: AppColors.surface,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          errorWidget: (_, _, _) => Container(
            color: AppColors.surface,
            child: const Center(
              child: Icon(
                Icons.broken_image_rounded,
                size: 48,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AppTextStyles.labelMedium);
  }
}

class _HtmlPreviewCard extends StatelessWidget {
  final String htmlContent;
  const _HtmlPreviewCard({required this.htmlContent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Html(
        data: htmlContent,
        style: {
          'body': Style(
            fontSize: FontSize(14),
            color: AppColors.textPrimary,
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
          ),
          'ul': Style(
            margin: Margins.only(bottom: 8),
            padding: HtmlPaddings.only(left: 20),
          ),
          'ol': Style(
            margin: Margins.only(bottom: 8),
            padding: HtmlPaddings.only(left: 20),
          ),
          'li': Style(margin: Margins.only(bottom: 4)),
        },
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final List<String> selected;
  final void Function(String) onToggle;

  static const _categories = [
    'Sarapan',
    'Makan Siang',
    'Makan Malam',
    'Snack',
    'Dessert',
    'Minuman',
    'Vegetarian',
    'Seafood',
    'Ayam',
    'Daging',
  ];

  const _CategorySelector({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppDimensions.lg),
        Text('Kategori', style: AppTextStyles.labelMedium),
        const SizedBox(height: AppDimensions.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((cat) {
            final isSelected = selected.contains(cat);
            return GestureDetector(
              onTap: () => onToggle(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.md,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.inputBorder,
                  ),
                ),
                child: Text(
                  cat,
                  style: AppTextStyles.caption.copyWith(
                    color: isSelected
                        ? AppColors.white
                        : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _OriginalUrlRow extends StatelessWidget {
  final String url;
  const _OriginalUrlRow({required this.url});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.link_rounded,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            url,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              decoration: TextDecoration.underline,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
