// Konverter dua arah antara format Quill Delta (dipakai oleh QuillEditorField)
// dan HTML (format penyimpanan ingredients/steps di Firebase
//
// Tag yang didukung: <p>, <div>, <ul><li>, <ol><li>, <b>/<strong>, <i>/<em>,
// <u>, <br>. Ini sengaja dibatasi ke toolbar yang tersedia di QuillEditorField
// (Bold, Italic, Underline, Bullet, Ordered) — bukan parser HTML lengkap.
//
// Dipakai oleh AddRecipeViewModel (delta → html saat simpan) dan
// EditRecipeViewModel (html → delta saat load, delta → html saat update).

import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';

abstract final class QuillHtmlConverter {
  // ── Delta JSON → HTML ───────────────────────────────────────────────────
  static String deltaToHtml(String deltaJson) {
    if (deltaJson.isEmpty) return '';
    try {
      final ops = Document.fromJson(
        jsonDecode(deltaJson) as List,
      ).toDelta().toList();

      final buffer = StringBuffer();
      final lineBuffer = StringBuffer();
      bool inBullet = false;
      bool inOrdered = false;

      void closeLists() {
        if (inBullet) {
          buffer.write('</ul>');
          inBullet = false;
        }
        if (inOrdered) {
          buffer.write('</ol>');
          inOrdered = false;
        }
      }

      void flushLine(Map<String, dynamic> lineAttrs) {
        final isBullet = lineAttrs['list'] == 'bullet';
        final isOrdered = lineAttrs['list'] == 'ordered';
        final lineContent = lineBuffer.toString();
        lineBuffer.clear();

        if (isBullet) {
          if (inOrdered) {
            buffer.write('</ol>');
            inOrdered = false;
          }
          if (!inBullet) {
            buffer.write('<ul>');
            inBullet = true;
          }
          buffer.write('<li>$lineContent</li>');
        } else if (isOrdered) {
          if (inBullet) {
            buffer.write('</ul>');
            inBullet = false;
          }
          if (!inOrdered) {
            buffer.write('<ol>');
            inOrdered = true;
          }
          buffer.write('<li>$lineContent</li>');
        } else {
          closeLists();
          if (lineContent.isNotEmpty) {
            buffer.write('<p>$lineContent</p>');
          } else {
            buffer.write('<br>');
          }
        }
      }

      for (final op in ops) {
        if (!op.isInsert) continue;

        final text = op.data.toString();
        final attrs = Map<String, dynamic>.from(op.attributes ?? {});

        if (text == '\n') {
          flushLine(attrs);
        } else {
          var content = _escapeHtml(text);
          if (attrs['bold'] == true) content = '<b>$content</b>';
          if (attrs['italic'] == true) content = '<i>$content</i>';
          if (attrs['underline'] == true) content = '<u>$content</u>';
          lineBuffer.write(content);
        }
      }

      if (lineBuffer.isNotEmpty) {
        flushLine({});
      }

      closeLists();
      return buffer.toString();
    } catch (e) {
      return deltaJson;
    }
  }

  static String deltaToPlainText(String deltaJson) {
    if (deltaJson.isEmpty) return '';
    try {
      final doc = Document.fromJson(jsonDecode(deltaJson) as List);
      return doc.toPlainText().trim();
    } catch (_) {
      return deltaJson;
    }
  }

  // ── HTML → Delta JSON ───────────────────────────────────────────────────
  // cukup untuk konten yang dihasilkan oleh deltaToHtml di atas
  // memakai <p>/<div>, <ul>/<ol><li>, <b>/<strong>, <i>/<em>, <u>.
  static String htmlToDelta(String html) {
    final trimmed = html.trim();
    if (trimmed.isEmpty) {
      return jsonEncode([
        {'insert': '\n'},
      ]);
    }

    final ops = <Map<String, dynamic>>[];

    final blockRegex = RegExp(
      r'<ul>(.*?)</ul>|<ol>(.*?)</ol>|<p>(.*?)</p>|<div>(.*?)</div>',
      caseSensitive: false,
      dotAll: true,
    );
    final liRegex = RegExp(
      r'<li>(.*?)</li>',
      caseSensitive: false,
      dotAll: true,
    );

    final matches = blockRegex.allMatches(trimmed).toList();

    if (matches.isEmpty) {
      // Fallback: tidak ada tag blok sama sekali, anggap satu paragraf polos
      ops.addAll(_parseInlineRuns(trimmed));
      ops.add({'insert': '\n'});
      return jsonEncode(ops);
    }

    for (final m in matches) {
      final ulContent = m.group(1);
      final olContent = m.group(2);
      final pContent = m.group(3) ?? m.group(4); // <p> atau <div>

      if (ulContent != null) {
        final items = liRegex.allMatches(ulContent).toList();
        if (items.isEmpty) continue;
        for (final li in items) {
          ops.addAll(_parseInlineRuns(li.group(1) ?? ''));
          ops.add({
            'insert': '\n',
            'attributes': {'list': 'bullet'},
          });
        }
      } else if (olContent != null) {
        final items = liRegex.allMatches(olContent).toList();
        if (items.isEmpty) continue;
        for (final li in items) {
          ops.addAll(_parseInlineRuns(li.group(1) ?? ''));
          ops.add({
            'insert': '\n',
            'attributes': {'list': 'ordered'},
          });
        }
      } else if (pContent != null) {
        final cleaned = pContent.replaceAll(
          RegExp(r'<br\s*/?>', caseSensitive: false),
          '',
        );
        if (cleaned.trim().isEmpty) {
          ops.add({'insert': '\n'});
        } else {
          ops.addAll(_parseInlineRuns(cleaned));
          ops.add({'insert': '\n'});
        }
      }
    }

    if (ops.isEmpty) ops.add({'insert': '\n'});
    return jsonEncode(ops);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────
  static List<Map<String, dynamic>> _parseInlineRuns(String html) {
    final ops = <Map<String, dynamic>>[];
    final tagRegex = RegExp(
      r'<(b|strong|i|em|u)>(.*?)</\1>|([^<]+)',
      caseSensitive: false,
      dotAll: true,
    );

    for (final m in tagRegex.allMatches(html)) {
      if (m.group(3) != null) {
        final text = _unescapeHtml(m.group(3)!);
        if (text.isNotEmpty) ops.add({'insert': text});
        continue;
      }

      final tag = (m.group(1) ?? '').toLowerCase();
      final inner = _unescapeHtml(m.group(2) ?? '');
      if (inner.isEmpty) continue;

      final attrs = <String, dynamic>{};
      if (tag == 'b' || tag == 'strong') attrs['bold'] = true;
      if (tag == 'i' || tag == 'em') attrs['italic'] = true;
      if (tag == 'u') attrs['underline'] = true;

      ops.add({'insert': inner, 'attributes': attrs});
    }

    return ops;
  }

  static String _escapeHtml(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  static String _unescapeHtml(String s) => s
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'");
}
