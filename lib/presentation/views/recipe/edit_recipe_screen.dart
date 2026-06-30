import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/quill_editor_field.dart';
import '../../viewmodels/edit_recipe_viewmodel.dart';
import '../../viewmodels/recipe_detail_viewmodel.dart';
import '../../viewmodels/recipe_viewmodel.dart';

class EditRecipeScreen extends ConsumerStatefulWidget {
  final String recipeId;
  const EditRecipeScreen({super.key, required this.recipeId});

  @override
  ConsumerState<EditRecipeScreen> createState() => _EditRecipeScreenState();
}

class _EditRecipeScreenState extends ConsumerState<EditRecipeScreen> {
  final _titleCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _picker = ImagePicker();
  bool _controllersInitialized = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  EditRecipeViewModel get _vm =>
      ref.read(editRecipeViewModelProvider(widget.recipeId).notifier);

  // Sync controller text dari state — hanya sekali, setelah data resep masuk.
  // (pola yang sama dipakai di ImportPreviewScreen)
  void _syncControllers(EditRecipeState state) {
    if (!_controllersInitialized && state.originalRecipe != null) {
      _titleCtrl.text = state.title;
      _durationCtrl.text = state.duration;
      _controllersInitialized = true;
    }
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
      // Refresh detail screen agar data langsung terupdate saat kembali
      ref
          .read(recipeDetailViewModelProvider(widget.recipeId).notifier)
          .loadRecipe(widget.recipeId);
      // Refresh collection screen agar list juga terupdate
      ref.read(recipeViewModelProvider.notifier).loadUserData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resep berhasil diperbarui! 🎉'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editRecipeViewModelProvider(widget.recipeId));
    _syncControllers(state);

    ref.listen(editRecipeViewModelProvider(widget.recipeId), (prev, next) {
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

    // ── Loading awal (sebelum data resep masuk) ───────────────────────────
    if (state.isLoading && state.originalRecipe == null) {
      return Scaffold(
        backgroundColor: AppColors.white,
        appBar: _appBar(),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // ── Resep tidak ditemukan ──────────────────────────────────────────────
    if (state.notFound) {
      return Scaffold(
        backgroundColor: AppColors.white,
        appBar: _appBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: AppColors.gray400,
                ),
                const SizedBox(height: AppDimensions.md),
                Text('Resep tidak ditemukan', style: AppTextStyles.h4),
                const SizedBox(height: AppDimensions.lg),
                AppButton(
                  title: 'Kembali',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── Form edit ───────────────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: _appBar(),
      body: GestureDetector(
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
              // ── Image Picker ───────────────────────────────────────────
              _EditImagePickerWidget(
                currentImageUrl: state.isImageRemoved
                    ? null
                    : state.currentImageUrl,
                newImageFile: state.newImageFile,
                onPick: _pickImage,
                onRemove: _vm.removeImage,
              ),

              const SizedBox(height: AppDimensions.xxl),

              // ── Judul ────────────────────────────────────────────────────
              AppInput(
                label: 'Judul Resep',
                placeholder: 'Misal : Sup Ayam',
                controller: _titleCtrl,
                errorText: state.titleError,
                onChanged: _vm.setTitle,
              ),

              // ── Durasi ───────────────────────────────────────────────────
              AppInput(
                label: 'Durasi (menit)',
                placeholder: 'Misal : 30',
                controller: _durationCtrl,
                keyboardType: TextInputType.number,
                errorText: state.durationError,
                onChanged: _vm.setDuration,
              ),

              const SizedBox(height: AppDimensions.xl),

              // ── Bahan-bahan ──────────────────────────────────────────────
              QuillEditorField(
                label: 'Bahan-bahan',
                placeholder: 'Satu bahan per baris...',
                minHeight: 150,
                initialValue: state.ingredientsDelta,
                errorText: state.ingredientsError,
                onChanged: _vm.setIngredientsDelta,
              ),

              // ── Langkah-langkah ──────────────────────────────────────────
              QuillEditorField(
                label: 'Langkah-langkah',
                placeholder: 'Jelaskan cara memasaknya...',
                minHeight: 200,
                initialValue: state.stepsDelta,
                errorText: state.stepsError,
                onChanged: _vm.setStepsDelta,
              ),

              const SizedBox(height: AppDimensions.sm),

              AppButton(
                title: 'Update Resep',
                onPressed: _handleSubmit,
                isLoading: state.isSaving,
              ),

              const SizedBox(height: AppDimensions.xxl),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar() => AppBar(
    backgroundColor: AppColors.white,
    title: const Text('Edit Resep'),
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
      onPressed: () => Navigator.pop(context),
    ),
    bottom: const PreferredSize(
      preferredSize: Size.fromHeight(1),
      child: Divider(height: 1),
    ),
  );
}

// ── Image Picker Widget (mendukung gambar lama dari network + gambar baru) ──
class _EditImagePickerWidget extends StatelessWidget {
  final String? currentImageUrl;
  final File? newImageFile;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _EditImagePickerWidget({
    required this.currentImageUrl,
    required this.newImageFile,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = newImageFile != null;
    final hasNetwork = !hasFile && (currentImageUrl?.isNotEmpty ?? false);
    final hasAnyImage = hasFile || hasNetwork;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: SizedBox(
        width: double.infinity,
        height: 200,
        child: hasAnyImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    onTap: onPick,
                    child: hasFile
                        ? Image.file(newImageFile!, fit: BoxFit.cover)
                        : CachedNetworkImage(
                            imageUrl: currentImageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, _) =>
                                Container(color: AppColors.gray200),
                            errorWidget: (_, _, _) =>
                                Container(color: AppColors.gray200),
                          ),
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
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.black.withOpacity(0.4),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: const Text(
                        'Ketuk untuk ganti',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.white, fontSize: 10),
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
                        'Upload Foto Masakan',
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
