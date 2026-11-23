import 'lexicon_en.dart';
import 'lexicon_tr.dart';
import 'tokens.dart';

/// Uzundan kısaya sıralı RegExp seçeneği; boşluklar `\s+` olur.
String alt(Iterable<String> words) {
  final list =
      words.toSet().toList()..sort((a, b) => b.length.compareTo(a.length));
  return list.map((w) => w.replaceAll(' ', r'\s+')).join('|');
}

final String wdTrAlt = alt(trWeekdays.keys);
final String wdEnAlt = alt(enWeekdays.keys);
final String wdFullAlt = alt([...trWeekdays.keys, ...enWeekdays.keys]);
final String wdAbbrAlt = alt(enWeekdayAbbr.keys);

/// Türkçe kısa günler: yalnızca ardından saat gelirse.
final String wdTrShortAlt =
    '(?:${alt(trWeekdayShort.keys)})'
    r'(?=\.?\s+\d)';
final String monthAlt = alt([...trMonths.keys, ...enMonths.keys]);
final String enMonthAlt = alt(enMonths.keys);
final String trNumAlt = alt(trNumbers.keys);
final String enNumAlt = alt(enNumbers.keys);
final String numWordAlt = alt([...trNumbers.keys, ...enNumbers.keys]);
final String dayPartAlt = alt([...trDayParts.keys, ...enDayParts.keys]);

/// Tarih benzeri ama tanınmamış kalıntıyı yakalar (güven hesabı için).
final RegExp dateishRe = RegExp(
  r'\d|(?<![a-z])(?:' +
      alt([
        ...trWeekdays.keys.where((k) => k.length > 3),
        ...enWeekdays.keys,
        ...trMonths.keys,
        ...enMonths.keys.where((k) => k.length > 3),
        'bugun',
        'yarin',
        'today',
        'tomorrow',
        'tonight',
        'saat',
        'haftaya',
        'oclock',
        "o'clock",
      ]) +
      r')(?![a-z])',
);

final RegExp _space = RegExp(r'\s+');

int? weekdayOf(String folded) =>
    trWeekdays[folded] ??
    enWeekdays[folded] ??
    enWeekdayAbbr[folded] ??
    trWeekdayShort[folded];

bool isEnAbbr(String folded) => enWeekdayAbbr.containsKey(folded);

int? monthOf(String folded) {
  final k =
      folded.endsWith('.') ? folded.substring(0, folded.length - 1) : folded;
  return trMonths[k] ?? enMonths[k];
}

/// Rakam ya da sayı sözcüğü ("iki", "three", "an").
int? numberOf(String s) => int.tryParse(s) ?? trNumbers[s] ?? enNumbers[s];

DayPart? dayPartOf(String s) {
  final k = s.replaceAll(_space, ' ');
  return trDayParts[k] ?? enDayParts[k];
}

final RegExp _trChars = RegExp('[çğıöşüÇĞİÖŞÜ]');
final RegExp _word = RegExp(r"[a-z]+");

/// Satır dili: Türkçe harfler ve sık sözcüklerden basit puan. Eşitlikte TR.
Lang detectLang(String original, String folded) {
  var tr = 0;
  var en = 0;
  if (_trChars.hasMatch(original)) tr += 2;
  for (final m in _word.allMatches(folded)) {
    final w = m[0]!;
    if (trHints.contains(w) ||
        trWeekdays.containsKey(w) ||
        trMonths.containsKey(w)) {
      tr++;
    }
    if (enHints.contains(w) || enMonths.containsKey(w) && w.length > 3) en++;
  }
  // "15'te" gibi ekler güçlü Türkçe işaretidir.
  if (folded.contains(RegExp(r"\d'(?:te|de|ta|da|e|a|ye|ya)\b"))) tr += 2;
  if (folded.contains(RegExp(r'\d\s*[ap]\.?m\b'))) en += 2;
  return en > tr ? Lang.en : Lang.tr;
}
