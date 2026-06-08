import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/quill_editor_field.dart';
import '../../viewmodels/add_recipe_viewmodel.dart';

class AddRecipeManualScreen extends ConsumerStatefulWidget {
  const AddRecipeManualScreen({super.key});

  @override
  ConsumerState<AddRecipeManualScreen> createState() =>
      _AddRecipeManualScreenState();
}

class _AddRecipeManualScreenState extends ConsumerState<AddRecipeManualScreen> {
  final _titleCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _picker = ImagePicker();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _durationCtrl.dispose();
    ref.read(addRecipeViewModelProvider.notifier).reset();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final xfile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
    if (xfile == null) return;
    ref.read(addRecipeViewModelProvider.notifier).setImage(File(xfile.path));
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();
    final success = await ref
        .read(addRecipeViewModelProvider.notifier)
        .submit();
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
    final vmState = ref.watch(addRecipeViewModelProvider);

    ref.listen(addRecipeViewModelProvider, (prev, next) {
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
        title: const Text('Tulis Resep'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
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
              // ── Image Picker ────────────────────────────────
              _ImagePickerWidget(
                imageFile: vmState.imageFile,
                onPick: _pickImage,
                onRemove: () =>
                    ref.read(addRecipeViewModelProvider.notifier).removeImage(),
              ),

              const SizedBox(height: AppDimensions.xxl),

              // ── Judul ───────────────────────────────────────
              AppInput(
                label: 'Judul Resep',
                placeholder: 'Misal : Sup Ayam',
                controller: _titleCtrl,
                errorText: vmState.titleError,
                onChanged: (v) =>
                    ref.read(addRecipeViewModelProvider.notifier).setTitle(v),
              ),

              // ── Durasi ──────────────────────────────────────
              AppInput(
                label: 'Durasi (menit)',
                placeholder: 'Misal : 30',
                controller: _durationCtrl,
                keyboardType: TextInputType.number,
                errorText: vmState.durationError,
                onChanged: (v) => ref
                    .read(addRecipeViewModelProvider.notifier)
                    .setDuration(v),
              ),

              // ── Kategori ────────────────────────────────────
              _CategorySelector(
                selected: vmState.selectedCategories,
                onToggle: (cat) => ref
                    .read(addRecipeViewModelProvider.notifier)
                    .toggleCategory(cat),
              ),

              const SizedBox(height: AppDimensions.xl),

              // ── Bahan-bahan ─────────────────────────────────
              QuillEditorField(
                label: 'Bahan-bahan',
                placeholder: 'Satu bahan per baris...',
                minHeight: 150,
                errorText: vmState.ingredientsError,
                onChanged: (json) => ref
                    .read(addRecipeViewModelProvider.notifier)
                    .setIngredientsDelta(json),
              ),

              // ── Langkah-langkah ─────────────────────────────
              QuillEditorField(
                label: 'Langkah-langkah',
                placeholder: 'Jelaskan cara memasaknya...',
                minHeight: 200,
                errorText: vmState.stepsError,
                onChanged: (json) => ref
                    .read(addRecipeViewModelProvider.notifier)
                    .setStepsDelta(json),
              ),

              const SizedBox(height: AppDimensions.sm),

              AppButton(
                title: 'Simpan Resep',
                onPressed: _handleSubmit,
                isLoading: vmState.isLoading,
              ),

              const SizedBox(height: AppDimensions.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Image Picker Widget ───────────────────────────────────────
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

// ── Category Selector ─────────────────────────────────────────
class _CategorySelector extends StatelessWidget {
  final List<String> selected;
  final ValueChanged<String> onToggle;

  static const _categories = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Healthy',
    'Quick',
  ];

  const _CategorySelector({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kategori', style: AppTextStyles.labelMedium),
        const SizedBox(height: AppDimensions.sm),
        Wrap(
          spacing: AppDimensions.sm,
          runSpacing: AppDimensions.sm,
          children: _categories.map((cat) {
            final isSelected = selected.contains(cat);
            return GestureDetector(
              onTap: () => onToggle(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.lg,
                  vertical: AppDimensions.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.inputBorder,
                  ),
                ),
                child: Text(
                  cat,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isSelected ? AppColors.white : AppColors.textPrimary,
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
