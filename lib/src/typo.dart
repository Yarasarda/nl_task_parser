// Yazım yanlışı telafisi: tanınmayan kelime bir gün/ay/göreli gün adına çok
// yakınsa ("yrın", "perşmbe", "15 ekmi", "tomorow") düzeltilmiş halini önerir.
//
// Korumalar (yanlış düzeltme, düzeltmemekten pahalıdır):
// * İlk harf aynı olmalı; uzaklık 1, ikisi de 7+ harfse 2.
// * Bir harf uzak gerçek kelimeler ("yarım", "aksan", "match") hariç.
// * Dört harfli adaylar (cuma, mart, ekim…) yalnızca hemen yanında bir sayı
//   varsa: "Mert'le kahve" Mart olmaz, "15 mrat" olur.
// * İki aday aynı uzaklıktaysa düzeltme yok.
// * Atlanan harf (yalnız silme): kelime adayın alt dizisiyse 2 harfe kadar
//   eksik olabilir ("prşmbe"); ilk harf atlandıysa ("arın") yanında sayı şart.
// * Boşluk atlanmışsa ("saat15", "yarın15te") araya boşluk konur.
// * Ek almış kelimede ("perşmbeye") gövde düzeltilir, ek korunur; gövde
//   zaten doğruysa ("pazarlık") dokunulmaz.

import 'fold.dart';
import 'lexicon_en.dart';
import 'lexicon_tr.dart';

/// Satırdaki bir düzeltme: `[start, end)` özgün satırda, yerine [replacement].
class TypoFix {
  const TypoFix(this.start, this.end, this.replacement);

  final int start;
  final int end;
  final String replacement;

  @override
  String toString() => 'TypoFix($start, $end, "$replacement")';
}

/// Düzeltmede aday olan tam sözcükler (katlanmış).
const List<String> _candidates = [
  // Türkçe
  'pazartesi', 'sali', 'carsamba', 'persembe', 'cuma', 'cumartesi', 'pazar',
  'ocak', 'subat', 'mart', 'nisan', 'mayis', 'haziran', 'temmuz', 'agustos',
  'eylul', 'ekim', 'kasim', 'aralik',
  'bugun', 'yarin', 'haftaya', 'aksam', 'sabah', 'ogleden',
  // İngilizce
  'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday',
  'sunday', 'january', 'february', 'march', 'april', 'june', 'july',
  'august', 'september', 'october', 'november', 'december',
  'today', 'tomorrow', 'tonight', 'morning', 'evening', 'afternoon',
];

/// Ek olarak ayrılabilecek sonlar (katlanmış), uzundan kısaya.
const List<String> _suffixes = [
  'nden',
  'ndan',
  'nde',
  'nda',
  'den',
  'dan',
  'ten',
  'tan',
  'ye',
  'ya',
  'de',
  'da',
  'te',
  'ta',
  'yi',
  'ki',
  'e',
  'a',
  'i',
  'u',
];

final RegExp _word = RegExp(r'[a-z]+');
final RegExp _digit = RegExp(r'\d');

/// Boşluk atlanmış: harfler hemen ardından rakam ("saat15", "yarin15te").
final RegExp _gluedRe = RegExp(r'(?<![a-z0-9])([a-z]{3,})(?=\d)');

/// Ardından saat gelen ve kendisi düzeltme adayı olmayan sözcükler.
const Set<String> _timeWords = {'saat', 'at', 'from', 'until', 'kadar'};

/// Bir adaya bir harf uzak ama kendisi gerçek kelime olanlar (katlanmış).
const Set<String> _realWords = {
  'yarim',
  'aksan',
  'match',
  'mark',
  'mars',
  'marc',
  'ekin',
  'cami',
  'fried',
  'frida',
  'sabri',
  'sali',
  'gene',
  'gece',
  'azar',
  'esim',
  'ekip',
  'akim',
  'sabah',
  'ocaga',
};

/// Zaten bilinen sözcükler düzeltilmez.
final Set<String> _known = {
  ..._candidates,
  ...trWeekdays.keys,
  ...trMonths.keys,
  ...enWeekdays.keys,
  ...enWeekdayAbbr.keys,
  ...enMonths.keys,
};

/// [line] içinde, [covered] (satıra göre `[start, end)`) dışında kalan
/// kelimelerden düzeltilebilenleri döndürür.
List<TypoFix> findTypos(String line, List<(int, int)> covered) {
  final folded = foldForMatch(line);
  final fixes = <TypoFix>[];
  final words = _word.allMatches(folded).toList();
  final glued = <int>{}; // boşluğu atlanmış kelimelerin başlangıçları
  for (final g in _gluedRe.allMatches(folded)) {
    final w = g[1]!;
    final fixedWord =
        _known.contains(w) || _timeWords.contains(w) ? w : _match(w, true);
    if (fixedWord == null) continue;
    final wordEnd = g.start + w.length;
    final original = line.substring(g.start, wordEnd);
    fixes.add(
      TypoFix(
        g.start,
        wordEnd,
        '${fixedWord == w ? original : _recase(original, fixedWord)} ',
      ),
    );
    glued.add(g.start);
  }
  for (var i = 0; i < words.length; i++) {
    final m = words[i];
    if (glued.contains(m.start)) continue;
    if (covered.any((c) => m.start < c.$2 && m.end > c.$1)) continue;
    // Kelimenin içinde/yanında harf dışı ama harf olmayan bir parça varsa
    // (ör. "15te"nin "te"si) kelime değildir.
    if (m.start > 0 && _digit.hasMatch(folded[m.start - 1])) continue;
    final w = m[0]!;
    if (w.length < 3 || _known.contains(w) || _realWords.contains(w)) continue;

    final nearNumber = _numberNear(folded, words, i);
    // Üç harf ancak yanında sayı varsa ve yalnız harf atlamasıyla ("slı 18:00").
    if (w.length == 3 && !nearNumber) continue;
    final hit = _match(w, nearNumber);
    if (hit == null) continue;
    fixes.add(
      TypoFix(m.start, m.end, _recase(line.substring(m.start, m.end), hit)),
    );
  }
  fixes.sort((a, b) => a.start.compareTo(b.start));
  return fixes;
}

/// Kelimenin hemen önünde ya da arkasında (araya yalnız boşluk/nokta) sayı var mı.
bool _numberNear(String folded, List<RegExpMatch> words, int i) {
  final m = words[i];
  final before = folded.substring(0, m.start).trimRight();
  final after = folded.substring(m.end).trimLeft();
  return (before.isNotEmpty && _digit.hasMatch(before[before.length - 1])) ||
      (after.isNotEmpty && _digit.hasMatch(after[0]));
}

/// Düzeltilmiş katlanmış sözcük (ek dahil) ya da null.
String? _match(String w, bool nearNumber) {
  final whole = _best(w, nearNumber, requireTypo: false);
  if (whole != null) return whole;
  for (final s in _suffixes) {
    if (w.length - s.length < 4 || !w.endsWith(s)) continue;
    final stem = w.substring(0, w.length - s.length);
    if (_known.contains(stem)) return null; // "pazarlik" gibi doğru gövde
    final fixed = _best(stem, nearNumber, requireTypo: true);
    if (fixed != null) return fixed + s;
  }
  return null;
}

String? _best(String w, bool nearNumber, {required bool requireTypo}) {
  String? best;
  var bestDist = 99;
  var tie = false;
  void consider(String c, int d) {
    if (d < bestDist) {
      best = c;
      bestDist = d;
      tie = false;
    } else if (d == bestDist && c != best) {
      tie = true;
    }
  }

  for (final c in _candidates) {
    // Atlanan harfler (yalnız silme): kelime adayın alt dizisiyse iki harfe
    // kadar eksik olabilir. İlk harf atlandıysa ("arın") yanında sayı şart.
    final missing = c.length - w.length;
    // Üç harfli kelimede yalnız tek harf eksik olabilir ("maç" → march olmasın).
    final maxMissing = w.length == 3 ? 1 : 2;
    if (missing >= 1 &&
        missing <= maxMissing &&
        (w.length >= 5 || nearNumber)) {
      if (c[0] == w[0] && _isSubsequence(w, c)) {
        consider(c, missing);
        continue;
      }
      if (nearNumber && c[0] != w[0] && _isSubsequence(w, c.substring(1))) {
        consider(c, missing);
        continue;
      }
    }
    if (c[0] != w[0] || w.length < 4) continue;
    if ((c.length - w.length).abs() > 2) continue;
    if (c.length <= 4 && !nearNumber) continue;
    // İki harf fark yalnızca uzun kelimelerde: "money" pazartesi olmasın.
    final max = (w.length < c.length ? w.length : c.length) >= 7 ? 2 : 1;
    final d = _osa(w, c, max);
    if (d > max || (requireTypo && d == 0)) continue;
    // Dört harfli adayda harf değişimi fazla tutar ("eşim" → ekim, "ekip"):
    // yalnızca yer değiştirme ("ekmi") kabul.
    if (c.length <= 4 && d == 1 && !_sameLetters(w, c)) continue;
    consider(c, d);
  }
  return tie ? null : best;
}

bool _sameLetters(String a, String b) {
  if (a.length != b.length) return false;
  final x = a.split('')..sort();
  final y = b.split('')..sort();
  return x.join() == y.join();
}

/// [w]'nin harfleri sırasıyla [c] içinde geçiyor mu ("prsmbe" ⊂ "persembe").
bool _isSubsequence(String w, String c) {
  var j = 0;
  for (var i = 0; i < c.length && j < w.length; i++) {
    if (c.codeUnitAt(i) == w.codeUnitAt(j)) j++;
  }
  return j == w.length;
}

/// Bitişik harf yer değiştirmesini de sayan düzenleme uzaklığı (OSA);
/// [max]'ı aşınca erken çıkar.
int _osa(String a, String b, int max) {
  final n = a.length, m = b.length;
  if ((n - m).abs() > max) return max + 1;
  var prev2 = List<int>.filled(m + 1, 0);
  var prev = List<int>.generate(m + 1, (j) => j);
  var cur = List<int>.filled(m + 1, 0);
  for (var i = 1; i <= n; i++) {
    cur[0] = i;
    var rowMin = cur[0];
    for (var j = 1; j <= m; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      var v = prev[j] + 1;
      if (cur[j - 1] + 1 < v) v = cur[j - 1] + 1;
      if (prev[j - 1] + cost < v) v = prev[j - 1] + cost;
      if (i > 1 &&
          j > 1 &&
          a.codeUnitAt(i - 1) == b.codeUnitAt(j - 2) &&
          a.codeUnitAt(i - 2) == b.codeUnitAt(j - 1) &&
          prev2[j - 2] + 1 < v) {
        v = prev2[j - 2] + 1;
      }
      cur[j] = v;
      if (v < rowMin) rowMin = v;
    }
    if (rowMin > max) return max + 1;
    final t = prev2;
    prev2 = prev;
    prev = cur;
    cur = t;
  }
  return prev[m];
}

/// Özgün kelimenin büyük harfle başlamasını korur.
String _recase(String original, String fixed) {
  if (original.isNotEmpty &&
      original[0] != original[0].toLowerCase() &&
      fixed.isNotEmpty) {
    return fixed[0].toUpperCase() + fixed.substring(1);
  }
  return fixed;
}

/// Düzeltmeleri uygular; düzeltilmiş metindeki bir konumu özgün metne
/// çevirmek için eşleyici döndürür.
(String, int Function(int)) applyFixes(String line, List<TypoFix> fixes) {
  final b = StringBuffer();
  final segs = <(int, int, int, int)>[]; // origS, origE, newS, newE
  var i = 0;
  for (final f in fixes) {
    b.write(line.substring(i, f.start));
    final ns = b.length;
    b.write(f.replacement);
    segs.add((f.start, f.end, ns, b.length));
    i = f.end;
  }
  b.write(line.substring(i));

  int back(int p) {
    var delta = 0;
    for (final (os, oe, ns, ne) in segs) {
      if (p < ns) break;
      if (p <= ne) return p == ne ? oe : (p == ns ? os : oe);
      delta = oe - ne;
    }
    return p + delta;
  }

  return (b.toString(), back);
}
