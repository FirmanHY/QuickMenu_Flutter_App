import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';

class QuillEditorField extends StatefulWidget {
  final String? label;
  final String? placeholder;
  final String? errorText;
  final double minHeight;
  final ValueChanged<String>? onChanged;
  final String? initialValue;

  const QuillEditorField({
    super.key,
    this.label,
    this.placeholder,
    this.errorText,
    this.minHeight = 150,
    this.onChanged,
    this.initialValue,
  });

  @override
  State<QuillEditorField> createState() => QuillEditorFieldState();
}

class QuillEditorFieldState extends State<QuillEditorField> {
  late QuillController _controller;
  late final ScrollController _scrollController;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _controller = _buildController(widget.initialValue);

    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });

    _controller.addListener(() {
      widget.onChanged?.call(getJson());
    });
  }

  QuillController _buildController(String? jsonStr) {
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final doc = Document.fromJson(jsonDecode(jsonStr) as List);
        return QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (_) {}
    }
    return QuillController.basic();
  }

  String getJson() => jsonEncode(_controller.document.toDelta().toJson());

  String getPlainText() => _controller.document.toPlainText().trim();

  Color get _borderColor {
    if (widget.errorText != null) return AppColors.error;
    if (_isFocused) return AppColors.primary;
    return AppColors.inputBorder;
  }

  Color get _fillColor {
    if (_isFocused) return AppColors.primary.withOpacity(0.04);
    return AppColors.white;
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Label ──────────────────────────────────────────────
        if (widget.label != null) ...[
          Text(widget.label!, style: AppTextStyles.labelMedium),
          const SizedBox(height: 6),
        ],

        // ── Container ──────────────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: _fillColor,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: _borderColor,
              width: _isFocused || widget.errorText != null ? 1.5 : 1,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.12),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Toolbar — 1 baris, hanya yang perlu ───────────
              _buildToolbar(),

              // ── Divider ───────────────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 1,
                color: _isFocused
                    ? AppColors.primary.withOpacity(0.25)
                    : AppColors.gray100,
              ),

              // ── Editor area ───────────────────────────────────
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: widget.minHeight),
                child: QuillEditor(
                  controller: _controller,
                  focusNode: _focusNode,
                  scrollController: _scrollController,
                  config: QuillEditorConfig(
                    placeholder: widget.placeholder ?? 'Tulis disini...',
                    padding: const EdgeInsets.all(12),
                    autoFocus: false,
                    expands: false,
                    scrollable: true,
                    customStyles: DefaultStyles(
                      paragraph: DefaultTextBlockStyle(
                        AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        const HorizontalSpacing(0, 0),
                        const VerticalSpacing(2, 2),
                        const VerticalSpacing(0, 0),
                        null,
                      ),
                      placeHolder: DefaultTextBlockStyle(
                        AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.gray400,
                        ),
                        const HorizontalSpacing(0, 0),
                        const VerticalSpacing(0, 0),
                        const VerticalSpacing(0, 0),
                        null,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Error ──────────────────────────────────────────────
        if (widget.errorText != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              widget.errorText!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],

        const SizedBox(height: AppDimensions.lg),
      ],
    );
  }

  // ── Custom toolbar — hanya Bold, Italic, Underline, Bullet, Ordered ──
  Widget _buildToolbar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: _isFocused
            ? AppColors.primary.withOpacity(0.06)
            : AppColors.gray200,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusMd),
        ),
      ),
      child: Row(
        children: [
          // Undo
          _ToolbarIconBtn(
            icon: Icons.undo_rounded,
            tooltip: 'Undo',
            onTap: () => _controller.undo(),
          ),

          // Redo
          _ToolbarIconBtn(
            icon: Icons.redo_rounded,
            tooltip: 'Redo',
            onTap: () => _controller.redo(),
          ),

          _divider(),

          // Bold
          _ToolbarFormatBtn(
            icon: Icons.format_bold_rounded,
            tooltip: 'Bold',
            attribute: Attribute.bold,
            controller: _controller,
          ),

          // Italic
          _ToolbarFormatBtn(
            icon: Icons.format_italic_rounded,
            tooltip: 'Italic',
            attribute: Attribute.italic,
            controller: _controller,
          ),

          // Underline
          _ToolbarFormatBtn(
            icon: Icons.format_underline_rounded,
            tooltip: 'Underline',
            attribute: Attribute.underline,
            controller: _controller,
          ),

          _divider(),

          // Bullet list
          _ToolbarFormatBtn(
            icon: Icons.format_list_bulleted_rounded,
            tooltip: 'Bullet List',
            attribute: Attribute.ul,
            controller: _controller,
          ),

          // Ordered list
          _ToolbarFormatBtn(
            icon: Icons.format_list_numbered_rounded,
            tooltip: 'Ordered List',
            attribute: Attribute.ol,
            controller: _controller,
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 20,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    color: AppColors.gray400.withOpacity(0.4),
  );
}

// ── Undo / Redo button (tidak punya state aktif) ──────────────
class _ToolbarIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ToolbarIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: AppColors.gray600),
        ),
      ),
    );
  }
}

// ── Format button dengan state aktif (highlight primary) ──────
class _ToolbarFormatBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Attribute attribute;
  final QuillController controller;

  const _ToolbarFormatBtn({
    required this.icon,
    required this.tooltip,
    required this.attribute,
    required this.controller,
  });

  @override
  State<_ToolbarFormatBtn> createState() => _ToolbarFormatBtnState();
}

class _ToolbarFormatBtnState extends State<_ToolbarFormatBtn> {
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChange);
  }

  void _onControllerChange() {
    final attrs = widget.controller.getSelectionStyle().attributes;
    final active = _checkIsActive(attrs);
    if (active != _isActive) setState(() => _isActive = active);
  }

  bool _checkIsActive(Map<String, Attribute> attrs) {
    final key = widget.attribute.key;

    // List attribute (bullet/ordered) — cek key 'list' DAN value-nya
    // harus cocok persis, supaya bullet tidak ikut aktif saat ordered dipilih
    if (widget.attribute == Attribute.ul) {
      final listAttr = attrs['list'];
      return listAttr != null && listAttr.value == 'bullet';
    }
    if (widget.attribute == Attribute.ol) {
      final listAttr = attrs['list'];
      return listAttr != null && listAttr.value == 'ordered';
    }

    // Bold, Italic, Underline — cek key dan value == true
    return attrs.containsKey(key) && attrs[key]?.value == true;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: InkWell(
        onTap: () {
          if (_isActive) {
            widget.controller.formatSelection(
              Attribute.clone(widget.attribute, null),
            );
          } else {
            widget.controller.formatSelection(widget.attribute);
          }
        },
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _isActive
                ? AppColors.primary.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: _isActive ? AppColors.primary : AppColors.gray600,
          ),
        ),
      ),
    );
  }
}
