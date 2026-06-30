// Bottom sheet untuk menambah / menghapus tag resep.
// Setara dengan EditTagSheetContent di React Native.

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../widgets/app_button.dart';

class EditTagBottomSheet extends StatefulWidget {
  final List<String> initialTags;
  final Future<void> Function(List<String> tags) onSave;
  final bool isSaving;

  const EditTagBottomSheet({
    super.key,
    required this.initialTags,
    required this.onSave,
    this.isSaving = false,
  });

  static Future<void> show({
    required BuildContext context,
    required List<String> initialTags,
    required Future<void> Function(List<String> tags) onSave,
    bool isSaving = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditTagBottomSheet(
        initialTags: initialTags,
        onSave: onSave,
        isSaving: isSaving,
      ),
    );
  }

  @override
  State<EditTagBottomSheet> createState() => _EditTagBottomSheetState();
}

class _EditTagBottomSheetState extends State<EditTagBottomSheet> {
  late final List<String> _tags;
  final _controller = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tags = List<String>.from(widget.initialTags);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addTag() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (_tags.any((t) => t.toLowerCase() == text.toLowerCase())) {
      _controller.clear();
      return;
    }
    setState(() {
      _tags.add(text);
      _controller.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      await widget.onSave(List<String>.from(_tags));
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.xxl,
        AppDimensions.lg,
        AppDimensions.xxl,
        AppDimensions.xxl + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXxl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Drag Handle ───────────────────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.lg),

          // ── Title ─────────────────────────────────────────────────────────
          Text('Kelola Tag', style: AppTextStyles.h3),
          const SizedBox(height: AppDimensions.xs),
          Text(
            'Tambahkan tag untuk mengorganisasi resep',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppDimensions.xl),

          // ── Input tag baru ────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addTag(),
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Contoh: Vegetarian, Sehat, Cepat...',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.gray400,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.lg,
                      vertical: AppDimensions.md,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                      borderSide: const BorderSide(
                        color: AppColors.inputBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                      borderSide: const BorderSide(
                        color: AppColors.inputBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              GestureDetector(
                onTap: _addTag,
                child: Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: const Icon(Icons.add_rounded, color: AppColors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),

          // ── Tag chips ─────────────────────────────────────────────────────
          if (_tags.isNotEmpty) ...[
            Wrap(
              spacing: AppDimensions.sm,
              runSpacing: AppDimensions.sm,
              children: _tags.map((tag) {
                return Chip(
                  label: Text(
                    '#$tag',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  backgroundColor: AppColors.primaryLight.withOpacity(0.3),
                  side: BorderSide(color: AppColors.primaryLight),
                  deleteIcon: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  onDeleted: () => _removeTag(tag),
                );
              }).toList(),
            ),
            const SizedBox(height: AppDimensions.lg),
          ],

          // ── Simpan ────────────────────────────────────────────────────────
          AppButton(
            title: 'Simpan Tag',
            onPressed: _handleSave,
            isLoading: _isSaving || widget.isSaving,
          ),
        ],
      ),
    );
  }
}
