import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_router.dart';
import '../../../shared/widgets/app_button.dart';

// ── State lokal untuk URL input ───────────────────────────────
class _ImportUrlState {
  final String url;
  final String? error;

  const _ImportUrlState({this.url = '', this.error});

  _ImportUrlState copyWith({
    String? url,
    String? error,
    bool clearError = false,
  }) => _ImportUrlState(
    url: url ?? this.url,
    error: clearError ? null : error ?? this.error,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
class ImportUrlScreen extends StatefulWidget {
  const ImportUrlScreen({super.key});

  @override
  State<ImportUrlScreen> createState() => _ImportUrlScreenState();
}

class _ImportUrlScreenState extends State<ImportUrlScreen> {
  final _urlCtrl = TextEditingController();
  var _state = const _ImportUrlState();

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _handleSubmit() {
    final url = _state.url.trim();

    if (url.isEmpty) {
      setState(() {
        _state = _state.copyWith(error: 'URL tidak boleh kosong');
      });
      return;
    }

    if (!_isValidUrl(url)) {
      setState(() {
        _state = _state.copyWith(
          error: 'Masukkan URL yang valid (contoh: https://cookpad.com/...)',
        );
      });
      return;
    }

    FocusScope.of(context).unfocus();
    context.push(AppRoutes.importPreview, extra: url);
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      setState(() {
        _urlCtrl.text = data!.text!;
        _state = _state.copyWith(url: data.text!, clearError: true);
      });
      _urlCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _urlCtrl.text.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Import dari Link'),
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
              // ── Ilustrasi / Header ────────────────────────
              _ImportHeader(),

              const SizedBox(height: AppDimensions.xl),

              // ── URL Input ─────────────────────────────────
              Text('Link Resep', style: AppTextStyles.labelMedium),
              const SizedBox(height: AppDimensions.sm),
              _UrlInputField(
                controller: _urlCtrl,
                errorText: _state.error,
                onChanged: (v) => setState(
                  () => _state = _state.copyWith(url: v, clearError: true),
                ),
                onPaste: _pasteFromClipboard,
              ),

              const SizedBox(height: AppDimensions.lg),

              // ── Supported sources info ────────────────────
              _SupportedSourcesInfo(),
              const SizedBox(height: AppDimensions.xl),

              // ── Submit button ─────────────────────────────
              AppButton(title: 'Ambil Resep', onPressed: _handleSubmit),

              const SizedBox(height: AppDimensions.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ImportHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.xl),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.link_rounded, size: 48, color: AppColors.primary),
          const SizedBox(height: AppDimensions.md),
          Text(
            'Import Resep dari Internet',
            style: AppTextStyles.h3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            'Tempel link resep dari website favoritmu,\nkami akan mengambil detailnya otomatis.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _UrlInputField extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String> onChanged;
  final VoidCallback onPaste;

  const _UrlInputField({
    required this.controller,
    required this.errorText,
    required this.onChanged,
    required this.onPaste,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                keyboardType: TextInputType.url,
                autocorrect: false,
                textInputAction: TextInputAction.go,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'https://cookpad.com/id/resep/...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.gray400,
                  ),
                  prefixIcon: const Icon(
                    Icons.link_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
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
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.error),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.md,
                    vertical: AppDimensions.md,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Paste button
            GestureDetector(
              onTap: onPaste,
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: const Icon(
                  Icons.content_paste_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 14, color: AppColors.error),
              const SizedBox(width: 4),
              Text(
                errorText!,
                style: AppTextStyles.caption.copyWith(color: AppColors.error),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SupportedSourcesInfo extends StatelessWidget {
  static const _sources = [
    (
      icon: Icons.language_rounded,
      label: 'Website Resep',
      desc: 'Cookpad, Sajian Sedap, dll',
    ),
    (
      icon: Icons.play_circle_outline_rounded,
      label: 'YouTube',
      desc: 'Video dengan deskripsi resep',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sumber yang Didukung',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDimensions.sm),
        ..._sources.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(s.icon, size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.label, style: AppTextStyles.bodySmall),
                    Text(
                      s.desc,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
