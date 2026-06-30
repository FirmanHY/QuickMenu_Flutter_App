// Strategi deteksi (dua tahap):
// 1. Kalau teks ada header eksplisit ("Bahan:", "Cara:", dst) → ikuti header
//    itu apa adanya (mode "sticky", ganti tiap ketemu header baru).
// 2. Kalau gak ada header sama sekali → tebak per baris: baris yang diawali
//    angka+satuan ("2 sdm", "200 gr") atau bullet/emoji dianggap ingredient,
//    sisanya dianggap steps.
//

abstract final class SmartPasteParser {
  // Matches section headers that introduce ingredients, including sub-sections
  // like "Bahan Utama :", "Bumbu Marinasi :", "Sambal Kecap :", etc.
  static final _ingredientHeaderRegex = RegExp(
    r'^(bahan(-bahan)?|bumbu|sambal|saus|topping|pelengkap|garnish|marinad\w*|ingredients?)'
    r'(\s+\w+)*\s*[:\-]?\s*$',
    caseSensitive: false,
  );
  // Matches step section headers anchored at line start, including patterns
  // like "Cara membuat :", "Tahap masak :", "Langkah-langkah :", etc.
  static final _stepHeaderRegex = RegExp(
    r'^(cara|langkah(-langkah)?|tahap|proses|prosedur|instructions?|steps?)'
    r'(\s+\w+)*\s*[:\-]?\s*$',
    caseSensitive: false,
  );
  // Safety net: short lines ending with ":" that aren't bullet/number lines —
  // treated as unknown sub-section headers when already in ingredient mode.
  static final _subSectionHeaderRegex = RegExp(
    r'^(?![\d\-\*]).{1,50}[:\-]\s*$',
  );
  static final _quantityHintRegex = RegExp(
    r'^\d+([.,/]\d+)?\s*(gr|gram|kg|ml|liter?|l|sdm|sdt|buah|siung|butir|'
    r'lembar|cup|sendok|ekor|ruas|ikat|secukupnya)\b',
    caseSensitive: false,
  );
  static final _leadingSymbolRegex = RegExp(r'^[^\w\s]{1,3}\s*', unicode: true);
  static final _numberPrefixRegex = RegExp(r'^\d+\s*[.):]\s*');

  // Bersihin bullet/emoji di depan baris, baru angka ("1.", "2)", dst).
  // PENTING: ini dipanggil SEBELUM cek _quantityHintRegex, karena baris
  // seperti "- 1 ikat kangkung" gak akan match `^\d+...` kalau bullet-nya
  // belum dibuang dulu.
  static String _cleanLine(String line) {
    final noSymbol = line.replaceFirst(_leadingSymbolRegex, '');
    return noSymbol.replaceFirst(_numberPrefixRegex, '').trim();
  }

  static SmartPasteResult parse(String rawText) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return const SmartPasteResult(
        titleGuess: '',
        ingredientLines: [],
        stepLines: [],
      );
    }

    final hasExplicitHeader = lines.any(
      (l) => _ingredientHeaderRegex.hasMatch(l) || _stepHeaderRegex.hasMatch(l),
    );

    // ── Tebak judul dari baris pertama (kalau bukan header/bahan/langkah) ──
    // Catatan: bullet/emoji DIBOLEHIN di baris judul (mis. "🍗 Ayam Bakar
    // Madu") — yang nge-disqualify cuma kalau setelah dibersihkan baris itu
    // match pola kuantitas/angka eksplisit, atau kalau input cuma 1 baris
    // doang (biar isinya gak ke-makan abis jadi judul kosongan).
    var startIndex = 0;
    var titleGuess = '';
    final first = lines.first;
    final firstCleaned = _cleanLine(first);
    final firstLooksLikeContent =
        _ingredientHeaderRegex.hasMatch(first) ||
        _stepHeaderRegex.hasMatch(first) ||
        _quantityHintRegex.hasMatch(firstCleaned) ||
        _numberPrefixRegex.hasMatch(first);
    if (lines.length > 1 && !firstLooksLikeContent && first.length <= 80) {
      titleGuess = first;
      startIndex = 1;
    }

    final ingredientLines = <String>[];
    final stepLines = <String>[];
    String mode = 'none'; // 'ingredients' | 'steps' | 'none'

    for (var i = startIndex; i < lines.length; i++) {
      final line = lines[i];

      if (_ingredientHeaderRegex.hasMatch(line)) {
        mode = 'ingredients';
        continue;
      }
      if (_stepHeaderRegex.hasMatch(line)) {
        mode = 'steps';
        continue;
      }
      // Unknown short "Sub-header :" while already in ingredient mode → skip.
      if (mode == 'ingredients' && _subSectionHeaderRegex.hasMatch(line)) {
        continue;
      }

      final cleaned = _cleanLine(line);
      if (cleaned.isEmpty) continue;

      if (!hasExplicitHeader) {
        // Gak ada header sama sekali → tebak per baris (gak "sticky").
        // Sinyalnya CUMA pola kuantitas ("2 sdm", "200 gr") yang dicek di
        // teks yang sudah dibersihkan dari bullet — bullet/emoji doang
        // BUKAN sinyal kuat karena dipakai juga di baris steps.
        mode = _quantityHintRegex.hasMatch(cleaned) ? 'ingredients' : 'steps';
      } else if (mode == 'none') {
        // Ada header di teks, tapi baris ini muncul SEBELUM header pertama
        // → masukkan ke steps sebagai default aman
        mode = 'steps';
      }

      if (mode == 'ingredients') {
        ingredientLines.add(cleaned);
      } else {
        stepLines.add(cleaned);
      }
    }

    return SmartPasteResult(
      titleGuess: titleGuess,
      ingredientLines: ingredientLines,
      stepLines: stepLines,
    );
  }

  /// nge-attribute source badge waktu Smart Paste dipicu dari URL Import yang
  /// gagal scrape.
  static String detectPlatform(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('instagram.com')) return 'Instagram';
    if (lower.contains('tiktok.com')) return 'TikTok';
    if (lower.contains('youtube.com') || lower.contains('youtu.be'))
      return 'Youtube';
    return 'Web';
  }
}

class SmartPasteResult {
  final String titleGuess;
  final List<String> ingredientLines;
  final List<String> stepLines;

  const SmartPasteResult({
    required this.titleGuess,
    required this.ingredientLines,
    required this.stepLines,
  });

  bool get hasIngredients => ingredientLines.isNotEmpty;
  bool get hasSteps => stepLines.isNotEmpty;

  String get ingredientsHtml => _toHtmlList(ingredientLines, ordered: false);
  String get stepsHtml => _toHtmlList(stepLines, ordered: true);

  static String _toHtmlList(List<String> items, {required bool ordered}) {
    if (items.isEmpty) return '';
    final tag = ordered ? 'ol' : 'ul';
    final li = items.map((i) => '<li>${_escape(i)}</li>').join();
    return '<$tag>$li</$tag>';
  }

  static String _escape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}
