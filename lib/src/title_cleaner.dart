import 'dart:typed_data';

import 'tokens.dart';

/// Tanınan parçaların bıraktığı boşlukları, sarkan bağlaçları ve
/// noktalamayı toplar. Bağlaçlar yalnızca bir parçaya bitişikse atılır:
/// "talk to John on friday" → "talk to John".

/// Parçadan hemen önce gelirse atılır (İngilizce).
const _beforeEn = {
  'at',
  'on',
  'in',
  'the',
  'from',
  'for',
  'around',
  'about',
  'starting',
  'approx',
  'every',
  'each',
  'of',
  'this',
};

/// Parçadan hemen önce gelirse atılır (Türkçe).
const _beforeTr = {'saat'};

/// Parçadan hemen sonra gelirse atılır.
const _after = {
  'de',
  'da',
  'te',
  'ta',
  'gunu',
  'gunleri',
  'arasi',
  'arasinda',
  'itibaren',
  'itibariyle',
  'gibi',
  'civari',
  'civarinda',
  'sularinda',
  'kadar',
  'saatinde',
  'saatte',
  'tarihinde',
  'sharp',
  'onwards',
  "o'clock",
  'oclock',
  'of',
};

/// İki parçanın arasında tek başına kalırsa atılır.
const _between = {'ve', 'ile', 'and', 'at', 'on', 'saat', 'the', 'of', '&'};

final RegExp _wordRe = RegExp(r'\S+');
final RegExp _edgePunct = RegExp(r"^[^\w']+|[^\w']+$");
final RegExp _ws = RegExp(r'\s+');
final RegExp _spaceBeforePunct = RegExp(r'\s+([,;:!?.)\]])');
final RegExp _repeatedSep = RegExp(r'([,;])(?:\s*[,;])+');
final RegExp _emptyBrackets = RegExp(r'\(\s*\)|\[\s*\]');
final RegExp _trimEdges = RegExp(r'^[\s,;:\-–—/|·•.+]+|[\s,;:\-–—/|·•.+]+$');
final RegExp _itemSep = RegExp(
  r'\s*(?:[,;]|\s(?:ve|and|&)\s)\s*',
  caseSensitive: false,
);

/// [mask]: 1 = tanınmış parça, 2 = atılan (madde imi), 0 = metin.
String joinRemainder(String line, String folded, Uint8List mask, Lang lang) {
  final before = lang == Lang.en ? _beforeEn : _beforeTr;
  final out = StringBuffer();
  var i = 0;
  final n = line.length;
  while (i < n) {
    if (mask[i] != 0) {
      i++;
      continue;
    }
    final s = i;
    while (i < n && mask[i] == 0) {
      i++;
    }
    final e = i;
    final prevSpan = s > 0 && mask[s - 1] == 1;
    final nextSpan = e < n && mask[e] == 1;
    final words = <(int, int, String)>[
      for (final m in _wordRe.allMatches(folded.substring(s, e)))
        (s + m.start, s + m.end, m[0]!.replaceAll(_edgePunct, '')),
    ];
    if (words.isEmpty) continue;
    if (prevSpan &&
        nextSpan &&
        words.every(
          (w) =>
              w.$3.isEmpty ||
              _between.contains(w.$3) ||
              _after.contains(w.$3) ||
              before.contains(w.$3),
        )) {
      continue;
    }
    var a = 0;
    var b = words.length;
    if (prevSpan) {
      while (a < b && (words[a].$3.isEmpty || _after.contains(words[a].$3))) {
        a++;
      }
    }
    if (nextSpan) {
      while (b > a &&
          (words[b - 1].$3.isEmpty || before.contains(words[b - 1].$3))) {
        b--;
      }
    }
    if (a >= b) continue;
    if (out.isNotEmpty) out.write(' ');
    out.write(line.substring(words[a].$1, words[b - 1].$2));
  }
  return out.toString();
}

String tidy(String s) {
  var t = s.replaceAll(_ws, ' ');
  t = t.replaceAllMapped(_spaceBeforePunct, (m) => m[1]!);
  t = t.replaceAllMapped(_repeatedSep, (m) => m[1]!);
  t = t.replaceAll(_emptyBrackets, '');
  t = t.replaceAll(_trimEdges, '');
  return t.replaceAll(_ws, ' ').trim();
}

/// "market: süt, ekmek, yumurta" → ("market", [süt, ekmek, yumurta]).
/// Yalnızca iki nokta solunda kısa bir başlık, sağında en az iki öğe varsa.
(String, List<String>)? splitSubtasks(String remainder) {
  final colon = remainder.indexOf(':');
  if (colon <= 0) return null;
  final head = tidy(remainder.substring(0, colon));
  if (head.isEmpty || head.split(' ').length > 6) return null;
  final items =
      remainder
          .substring(colon + 1)
          .split(_itemSep)
          .map(tidy)
          .where((x) => x.isNotEmpty)
          .toList();
  if (items.length < 2) return null;
  return (head, items);
}
