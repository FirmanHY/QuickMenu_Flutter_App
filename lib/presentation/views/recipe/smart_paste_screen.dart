// Dua tahap dalam satu screen:
//   1) Paste teks mentah (caption IG/TikTok, dll)
//   2) Preview hasil auto-detect (SmartPasteParser) → form yang sama dengan
//      Add/Edit Recipe, siap diedit sebelum disimpan.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/quill_editor_field.dart';
import '../../viewmodels/smart_paste_viewmodel.dart';

class SmartPasteScreen extends ConsumerStatefulWidget {
  final String? sourceUrl;
  const SmartPasteScreen({super.key, this.sourceUrl});

  @override
  ConsumerState<SmartPasteScreen> createState() => _SmartPasteScreenState();
}

class _SmartPasteScreenState extends ConsumerState<SmartPasteScreen> {
  final _rawTextCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _picker = ImagePicker();
  bool _previewInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(smartPasteViewModelProvider.notifier)
          .initSource(widget.sourceUrl);
    });
  }

  @override
  void dispose() {
    _rawTextCtrl.dispose();
    _titleCtrl.dispose();
    _durationCtrl.dispose();
    ref.read(smartPasteViewModelProvider.notifier).reset();
    super.dispose();
  }

  SmartPasteViewModel get _vm => ref.read(smartPasteViewModelProvider.notifier);

  void _clearAll() {
    _rawTextCtrl.clear();
    _titleCtrl.clear();
    _durationCtrl.clear();
    _previewInitialized = false;
    _vm.reset();
  }

  void _syncPreviewControllers(SmartPasteState state) {
    if (!_previewInitialized && state.isPreview) {
      _titleCtrl.text = state.title;
      _durationCtrl.text = state.duration;
      _previewInitialized = true;
    }
    if (!state.isPreview) {
      // user balik ke input → reset flag biar preview berikutnya ke-sync lagi
      _previewInitialized = false;
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null) return;
    _rawTextCtrl.text = data!.text!;
    _vm.setRawText(data.text!);
  }

  Future<void> _pickImage() async {
    final xfile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
    if (xfile == null) return;
    _vm.setImage(File(xfile.path));
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();
    final success = await _vm.submit();
    if (!mounted) return;
    if (success) {
      _clearAll();
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
    final state = ref.watch(smartPasteViewModelProvider);
    _syncPreviewControllers(state);

    ref.listen(smartPasteViewModelProvider, (prev, next) {
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

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _clearAll();
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          title: const Text('Smart Paste'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1),
          ),
        ),
        body: state.isPreview
            ? _PreviewEditBody(
                state: state,
                titleCtrl: _titleCtrl,
                durationCtrl: _durationCtrl,
                onBackToInput: _vm.backToInput,
                onPickImage: _pickImage,
                onRemoveImage: _vm.removeImage,
                onTitleChanged: _vm.setTitle,
                onDurationChanged: _vm.setDuration,
                onIngredientsChanged: _vm.setIngredientsDelta,
                onStepsChanged: _vm.setStepsDelta,
                onSubmit: _handleSubmit,
              )
            : _PasteInputBody(
                controller: _rawTextCtrl,
                errorText: state.pasteError,
                onChanged: _vm.setRawText,
                onPaste: _pasteFromClipboard,
                onDetect: _vm.detectAndPreview,
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tahap 1: Input teks mentah
// ─────────────────────────────────────────────────────────────────────────────
class _PasteInputBody extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String> onChanged;
  final VoidCallback onPaste;
  final VoidCallback onDetect;

  const _PasteInputBody({
    required this.controller,
    required this.errorText,
    required this.onChanged,
    required this.onPaste,
    required this.onDetect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenHorizontal,
        vertical: AppDimensions.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tempel Resep dari Caption', style: AppTextStyles.h3),
          const SizedBox(height: AppDimensions.sm),
          Text(
            'Cocok buat resep dari Instagram/TikTok yang gak bisa di-scan '
            'otomatis. Copy caption-nya, tempel di sini.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.lg),

          // ── Info card cara pakai ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Text(
                    'Kasih label "Bahan:" dan "Cara:" di teks biar deteksinya makin akurat. '
                    'Kalau gak ada label, sistem tetep coba nebak dari pola baris — '
                    'semua hasil deteksi bisa kamu edit dulu sebelum disimpan.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.lg),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Teks Resep', style: AppTextStyles.labelMedium),
              GestureDetector(
                onTap: onPaste,
                child: Row(
                  children: const [
                    Icon(
                      Icons.content_paste_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Paste dari Clipboard',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          TextField(
            controller: controller,
            onChanged: onChanged,
            maxLines: 12,
            minLines: 8,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText:
                  'Bahan:\n- 2 ayam fillet\n- 1 sdm bawang putih\n\nCara:\n1. Marinasi ayam...\n2. Goreng sampai matang...',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.gray400,
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.all(AppDimensions.md),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 14,
                  color: AppColors.error,
                ),
                const SizedBox(width: 4),
                Text(
                  errorText!,
                  style: AppTextStyles.caption.copyWith(color: AppColors.error),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppDimensions.xl),
          AppButton(title: 'Deteksi & Lanjut', onPressed: onDetect),
          const SizedBox(height: AppDimensions.xxl),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tahap 2: Preview & edit hasil deteksi (sebelum simpan)
// ─────────────────────────────────────────────────────────────────────────────
class _PreviewEditBody extends StatelessWidget {
  final SmartPasteState state;
  final TextEditingController titleCtrl;
  final TextEditingController durationCtrl;
  final VoidCallback onBackToInput;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onDurationChanged;
  final ValueChanged<String> onIngredientsChanged;
  final ValueChanged<String> onStepsChanged;
  final VoidCallback onSubmit;

  const _PreviewEditBody({
    required this.state,
    required this.titleCtrl,
    required this.durationCtrl,
    required this.onBackToInput,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.onTitleChanged,
    required this.onDurationChanged,
    required this.onIngredientsChanged,
    required this.onStepsChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenHorizontal,
          vertical: AppDimensions.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Kembali edit teks ────────────────────────────────────────
            GestureDetector(
              onTap: onBackToInput,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.arrow_back_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Edit teks yang ditempel',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.md),

            if (state.sourceUrl != null) ...[
              _SourceBadge(
                platform: state.sourcePlatform,
                url: state.sourceUrl!,
              ),
              const SizedBox(height: AppDimensions.lg),
            ],

            // ── Image Picker ─────────────────────────────────────────────
            _ImagePickerWidget(
              imageFile: state.imageFile,
              onPick: onPickImage,
              onRemove: onRemoveImage,
            ),

            const SizedBox(height: AppDimensions.xxl),

            AppInput(
              label: 'Judul Resep',
              placeholder: 'Misal : Sup Ayam',
              controller: titleCtrl,
              errorText: state.titleError,
              onChanged: onTitleChanged,
            ),

            AppInput(
              label: 'Durasi (menit)',
              placeholder: 'Misal : 30',
              controller: durationCtrl,
              keyboardType: TextInputType.number,
              errorText: state.durationError,
              onChanged: onDurationChanged,
            ),

            const SizedBox(height: AppDimensions.xl),

            Text(
              'Hasil deteksi otomatis di bawah ini — cek & rapikan dulu sebelum disimpan.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.sm),

            QuillEditorField(
              label: 'Bahan-bahan',
              placeholder: 'Satu bahan per baris...',
              minHeight: 150,
              initialValue: state.ingredientsDelta,
              errorText: state.ingredientsError,
              onChanged: onIngredientsChanged,
            ),

            QuillEditorField(
              label: 'Langkah-langkah',
              placeholder: 'Jelaskan cara memasaknya...',
              minHeight: 200,
              initialValue: state.stepsDelta,
              errorText: state.stepsError,
              onChanged: onStepsChanged,
            ),

            const SizedBox(height: AppDimensions.sm),

            AppButton(
              title: 'Simpan Resep',
              onPressed: onSubmit,
              isLoading: state.isSaving,
            ),

            const SizedBox(height: AppDimensions.xxl),
          ],
        ),
      ),
    );
  }
}

// ── Image Picker Widget (sama persis dengan punya Add Recipe) ──────────────
class _ImagePickerWidget extends StatelessWidget {
  final File? imageFile;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _ImagePickerWidget({
    required this.imageFile,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: SizedBox(
        width: double.infinity,
        height: 200,
        child: imageFile != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    onTap: onPick,
                    child: Image.file(imageFile!, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppColors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : GestureDetector(
                onTap: onPick,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.gray200,
                    border: Border.all(color: AppColors.inputBorder),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.camera_alt_rounded,
                        size: 40,
                        color: AppColors.gray400,
                      ),
                      const SizedBox(height: AppDimensions.sm),
                      Text(
                        'Upload Foto Masakan (opsional)',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

// ── Source badge kecil (kalau Smart Paste dipicu dari Import URL gagal) ────
class _SourceBadge extends StatelessWidget {
  final String platform;
  final String url;

  const _SourceBadge({required this.platform, required this.url});

  Color get _color => switch (platform.toLowerCase()) {
    'instagram' => const Color(0xFFE1306C),
    'tiktok' => AppColors.black,
    _ => AppColors.primary,
  };

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
          child: Text(
            'Dari $platform',
            style: AppTextStyles.caption.copyWith(
              color: _color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: Text(
            url,
            style: AppTextStyles.caption.copyWith(color: AppColors.gray400),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
