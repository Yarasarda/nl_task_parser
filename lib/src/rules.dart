// Düzenli ifadeler ham dizgelerden birleştirilir.
// ignore_for_file: prefer_interpolation_to_compose_strings

import 'model.dart';
import 'lexicon.dart';
import 'tokens.dart';

typedef TokBuilder = Tok? Function(RegExpMatch m, Lang lang);

/// Katlanmış metin üzerinde çalışan tek kural. Kurallar [rules] sırasıyla
/// denenir; önce gelen kural aralığı sahiplenir.
class Rule {
  Rule(String pattern, this.build) : re = RegExp(pattern);

  final RegExp re;
  final TokBuilder build;
}

// --- Ortak parçalar -------------------------------------------------------

/// Sayıdan sonra Türkçe hal ekleri: 15'te, 9da, 14'ten, 16'ya, 5'e.
const _numSuf = r"(?:'?(?:dan|den|tan|ten|da|de|ta|te|ya|ye|a|e))?";
const _wdSuf =
    r"(?:'?(?:ndan|nden|dan|den|nda|nde|nin|ya|ye|yi|yu|da|de|ta|te|a|e|i|u))?";
const _monSuf = r"(?:'?(?:dan|den|tan|ten|nin|in|un|ta|te|da|de|ya|ye|a|e|i))?";
const _ordSuf =
    r"(?:st|nd|rd|th|'?(?:sinde|sunde|inde|unde|nde|si|su|i|u|inci|unci|nci|ncu))?";
const _approx =
    r"(?:\s+(?:gibi|civari|civarinda|sularinda)(?![a-z]))?"
    r"(?:\s*o'?clock(?![a-z]))?";
const _end = r"(?![a-z\d])";

String _t(String p) =>
    r'(?<' +
    p +
    r'h>\d{1,2})(?:[:.](?<' +
    p +
    r'm>\d{2}))?' +
    r'(?:\s*(?<' +
    p +
    r'p>[ap])\.?m\b\.?)?';

final String _units =
    r'(?:gun|gunluk|hafta|ay|yil|saat|sa|dk|dakika|kisi|'
        r'tane|adet|sayfa|soru|km|kg|days?|weeks?|months?|hours?|hrs?|mins?|'
        r'minutes?|people|pages?|' +
    monthAlt +
    r')(?![a-z])';

final String _wdAny = '(?:$wdFullAlt|$wdAbbrAlt)';
final RegExp _wdScan = RegExp(
  '(?<![a-z])($wdFullAlt|$wdAbbrAlt|$wdTrShortAlt)(?:lari|leri|s)?(?![a-z])',
);
final RegExp _firstDigit = RegExp(r'\d');
final RegExp _spaces = RegExp(r'\s+');
final RegExp _ordinal = RegExp(r'\d(?:st|nd|rd|th)');

// --- Yardımcılar ----------------------------------------------------------

RawTime? _rawTime(RegExpMatch m, String p, {DayPart? dp}) {
  final hs = m.namedGroup('${p}h');
  if (hs == null) return null;
  final h = int.parse(hs);
  final ms = m.namedGroup('${p}m');
  final mi = ms == null ? 0 : int.parse(ms);
  final mer = m.namedGroup('${p}p');
  if (mi > 59) return null;
  if (mer != null) {
    if (h < 1 || h > 12) return null;
  } else if (h > 23) {
    return null;
  }
  final literal =
      mer == null && (h == 0 || h >= 13 || (hs.length == 2 && hs[0] == '0'));
  return RawTime(h, minute: mi, meridiem: mer, literal: literal, dayPart: dp);
}

RawTime _hourOnly(String hs, {DayPart? dp}) {
  final h = int.parse(hs);
  return RawTime(
    h,
    literal: h == 0 || h >= 13 || (hs.length == 2 && hs[0] == '0'),
    dayPart: dp,
  );
}

Tok _tok(RegExpMatch m, SpanKind kind) => Tok(m.start, m.end, kind);

Tok _recurTok(RegExpMatch m, Recur r, {DayPart? dp, double penalty = 0}) =>
    _tok(m, SpanKind.recurrence)
      ..recur = r
      ..dayPart = dp
      ..penalty = penalty;

List<int> _weekdaysIn(String s) => [
  for (final w in _wdScan.allMatches(s)) weekdayOf(w[1]!)!,
];

int? _year(String? y) {
  if (y == null) return null;
  final v = int.parse(y);
  return v < 100 ? 2000 + v : v;
}

Tok? _dateTok(RegExpMatch m, int? month, int day, int? year) {
  if (month == null || month < 1 || month > 12 || day < 1 || day > 31) {
    return null;
  }
  // Yılsız 29 Şubat'a izin ver: artık yılla doğrula.
  final check = DateTime(year ?? 2028, month + 1, 0).day;
  if (day > check) return null;
  return _tok(m, SpanKind.date)..date = AbsoluteDate(month, day, year);
}

Tok? _durationTok(RegExpMatch m, int minutes) {
  if (minutes <= 0 || minutes > 24 * 60 * 14) return null;
  final d = Duration(minutes: minutes);
  final relative = m.namedGroup('in') != null || m.namedGroup('later') != null;
  if (relative) return _tok(m, SpanKind.time)..fromNow = d;
  return _tok(m, SpanKind.duration)..duration = d;
}

double? _decimal(String? s) =>
    s == null ? null : double.tryParse(s.replaceAll(',', '.'));

Recur? _intervalRecur(String? n, String unit) {
  final count = n == null || n == 'other' ? 2 : numberOf(n);
  if (count == null || count < 1) return null;
  final u =
      unit.startsWith('gun') || unit.startsWith('day')
          ? 'DAILY'
          : unit.startsWith('hafta') || unit.startsWith('week')
          ? 'WEEKLY'
          : unit.startsWith('ay') || unit.startsWith('month')
          ? 'MONTHLY'
          : 'YEARLY';
  return Recur(u, interval: count);
}

// --- Kurucular ------------------------------------------------------------

Tok? _range(RegExpMatch m, Lang lang, {bool strong = false}) {
  final s = _rawTime(m, 's');
  final e = _rawTime(m, 'e');
  if (s == null || e == null) return null;
  if (strong &&
      m.namedGroup('sm') == null &&
      m.namedGroup('em') == null &&
      m.namedGroup('sp') == null &&
      m.namedGroup('ep') == null) {
    return null;
  }
  if (s.hour == e.hour && s.minute == e.minute && s.meridiem == e.meridiem) {
    return null;
  }
  return _tok(m, SpanKind.time)
    ..time = s
    ..endTime = e;
}

Tok? _clock(RegExpMatch m, Lang lang) {
  final t = _rawTime(m, '');
  if (t == null) return null;
  final tok = _tok(m, SpanKind.time)..time = t;
  // Türkçede "at" bir sözcüktür ("çöpü at 9'da"): parçaya katma.
  if (m.namedGroup('pre') == 'at' && lang == Lang.tr) {
    tok.start = m.start + m[0]!.indexOf(_firstDigit);
  }
  return tok;
}

Tok? _weekday(RegExpMatch m, Lang lang) {
  final mod = m.namedGroup('mod')?.replaceAll(_spaces, ' ');
  final abbr = m.namedGroup('ab');
  // İngilizce kısaltma ("sat", "sun") Türkçe cümlede gün sayılmaz; Türkçe
  // kısa günler zaten yalnızca ardından saat gelince eşleşir.
  if (abbr != null && isEnAbbr(abbr) && lang != Lang.en && mod == null) {
    return null;
  }
  final wd = weekdayOf(m.namedGroup('wd') ?? abbr!)!;
  WeekdayMode mode;
  if (m.namedGroup('nw') != null) {
    mode = WeekdayMode.nextWeek;
  } else {
    switch (mod) {
      case null:
        mode = WeekdayMode.bare;
      case 'bu' || 'this':
        mode = WeekdayMode.thisWeek;
      case 'gelecek' || 'onumuzdeki' || 'next' || 'coming':
        mode = WeekdayMode.nextStrict;
      default:
        mode = WeekdayMode.nextWeek;
    }
  }
  return _tok(m, SpanKind.date)..date = WeekdayDate(wd, mode);
}

Tok? _dayPartTime(RegExpMatch m, Lang lang) {
  final word = m.namedGroup('dp')!;
  final dp = dayPartOf(word);
  if (dp == null) return null;
  final t = _rawTime(m, '', dp: dp);
  if (t == null) return null;
  final tok =
      _tok(m, SpanKind.time)
        ..time = t
        ..dayPart = dp;
  if (m.namedGroup('this') != null || word == 'tonight') {
    tok.date = const RelativeDays(0);
  }
  return tok;
}

// --- Kural tablosu --------------------------------------------------------

final List<Rule> rules = [
  // Tekrar: hafta içi.
  Rule(r'\b(?:her\s+hafta\s?ici(?:\s+(?:her\s+)?gun(?:u|ler)?)?|'
      r'hafta\s?ici\s+her\s+gun|hafta\s?icleri|hafta\s?ici(?:nde)?|'
      r'(?:every|each)\s+weekday|(?:on\s+)?weekdays|'
      r'monday\s+(?:to|through|thru|-)\s+friday|mon\s*-\s*fri|'
      r'pazartesi(?:den)?\s*(?:-|ile)\s*cuma(?:ya)?(?:\s+arasi)?'
      r'(?:\s+her\s+gun)?)(?![a-z])', (m, lang) {
    final text = m[0]!.replaceAll(_spaces, ' ');
    final alone =
        text == 'hafta ici' || text == 'haftaici' || text == 'hafta icinde';
    return _recurTok(
      m,
      Recur('WEEKLY', byDay: [1, 2, 3, 4, 5]),
      penalty: alone ? 0.1 : 0,
    );
  }),
  // Tekrar: hafta sonları.
  Rule(
    r'\b(?:her\s+hafta\s?sonu|hafta\s?sonlari|(?:every|each)\s+weekend|'
    r'(?:on\s+)?weekends)(?![a-z])',
    (m, lang) => _recurTok(m, Recur('WEEKLY', byDay: [6, 7])),
  ),
  // Tekrar: "iki haftada bir", "3 günde bir", "her iki haftada bir".
  Rule(
    r'\b(?:her\s+)?(?<n>\d{1,2}|' +
        trNumAlt +
        r')\s+(?<u>gun|hafta|ay|yil|sene)(?:da|de|ta|te)\s+bir(?![a-z])',
    (m, lang) {
      final r = _intervalRecur(m.namedGroup('n'), m.namedGroup('u')!);
      return r == null ? null : _recurTok(m, r);
    },
  ),
  Rule(
    r'\bher\s+(?<n>\d{1,2}|' +
        trNumAlt +
        r')\s+(?<u>gun|hafta|ay|yil)(?![a-z])',
    (m, lang) {
      final r = _intervalRecur(m.namedGroup('n'), m.namedGroup('u')!);
      return r == null ? null : _recurTok(m, r);
    },
  ),
  Rule(
    r'\bgun\s+asiri(?![a-z])',
    (m, lang) => _recurTok(m, Recur('DAILY', interval: 2)),
  ),
  Rule(
    r'\b(?:every|each)\s+(?<n>other|\d{1,2}|' +
        enNumAlt +
        r')\s+(?<u>days?|weeks?|months?|years?)(?![a-z])',
    (m, lang) {
      final r = _intervalRecur(m.namedGroup('n'), m.namedGroup('u')!);
      return r == null ? null : _recurTok(m, r);
    },
  ),
  Rule(
    r'\b(?:bi-?weekly|fortnightly|every\s+fortnight)(?![a-z])',
    (m, lang) => _recurTok(m, Recur('WEEKLY', interval: 2)),
  ),
  // Tekrar: ayın belirli günü.
  Rule(
    r"\bher\s+ay(?:in)?\s+(?<d>\d{1,2})'?"
    r'(?:sinde|sunde|inde|unde|nde|sine|sune|ine|une|si|su|i|u)?(?![a-z\d])',
    (m, lang) {
      final d = int.parse(m.namedGroup('d')!);
      if (d < 1 || d > 31) return null;
      return _recurTok(m, Recur('MONTHLY', byMonthDay: d));
    },
  ),
  Rule(
    r'\bher\s+ayin\s+(?<fl>ilk|son)\s+gun(?:u|unde)?(?![a-z])',
    (m, lang) => _recurTok(
      m,
      Recur('MONTHLY', byMonthDay: m.namedGroup('fl') == 'ilk' ? 1 : -1),
    ),
  ),
  Rule(r'\b(?:(?:every|each)\s+month\s+on\s+the\s+|monthly\s+on\s+the\s+|'
      r'(?:every|each)\s+)(?<d>\d{1,2})(?:st|nd|rd|th)?(?:\s+of\s+the\s+month)?'
      r'(?![a-z\d])', (m, lang) {
    final d = int.parse(m.namedGroup('d')!);
    if (d < 1 || d > 31) return null;
    // "every 15" tek başına anlamsız: sıra eki ya da "month" şart.
    if (!m[0]!.contains('month') && !_ordinal.hasMatch(m[0]!)) {
      return null;
    }
    return _recurTok(m, Recur('MONTHLY', byMonthDay: d));
  }),
  Rule(
    r'\b(?:on\s+)?the\s+(?<d>\d{1,2})(?:st|nd|rd|th)?\s+of\s+(?:every|each)\s+'
    r'month(?![a-z])',
    (m, lang) {
      final d = int.parse(m.namedGroup('d')!);
      if (d < 1 || d > 31) return null;
      return _recurTok(m, Recur('MONTHLY', byMonthDay: d));
    },
  ),
  // Tekrar: "her salı ve perşembe", "every tuesday and thursday".
  Rule(
    r'\b(?:her|every|each)\s+(?<other>other\s+)?' +
        _wdAny +
        r'(?:\s*(?:,|ve|and|ile|&)\s*(?:her\s+|every\s+)?' +
        _wdAny +
        r')*(?:\s+gun(?:u|leri))?(?![a-z])',
    (m, lang) {
      final days = _weekdaysIn(m[0]!);
      if (days.isEmpty) return null;
      return _recurTok(
        m,
        Recur(
          'WEEKLY',
          byDay: days,
          interval: m.namedGroup('other') != null ? 2 : 1,
        ),
      );
    },
  ),
  // Tekrar: çoğul gün adı: "salıları", "salı ve perşembeleri", "tuesdays".
  Rule(
    r'\b(?:(?:' +
        wdTrAlt +
        r')\s*(?:,|ve)\s*)*(?:' +
        wdTrAlt +
        r')(?:lari|leri)(?![a-z])',
    (m, lang) => _recurTok(m, Recur('WEEKLY', byDay: _weekdaysIn(m[0]!))),
  ),
  Rule(
    r'\b(?:on\s+)?(?:(?:' +
        wdEnAlt +
        r')s?\s*(?:,|and|&)\s*)*(?:' +
        wdEnAlt +
        r')s(?![a-z])',
    (m, lang) => _recurTok(m, Recur('WEEKLY', byDay: _weekdaysIn(m[0]!))),
  ),
  // Tekrar: "her sabah", "every evening", "akşamları", "mornings".
  Rule(
    r'\b(?:(?:her|every|each)\s+(?<dp>' +
        dayPartAlt +
        r')|(?<dpl>ogleden\s+sonra|aksam|sabah|oglen|ogle|gece)(?:lari|leri)|'
            r'(?<dpe>morning|afternoon|evening|night)s)(?![a-z])',
    (m, lang) {
      final w =
          m.namedGroup('dp') ?? m.namedGroup('dpl') ?? m.namedGroup('dpe');
      return _recurTok(m, Recur('DAILY'), dp: dayPartOf(w!));
    },
  ),
  // Tekrar: günlük / haftalık / aylık / yıllık.
  Rule(
    r'\b(?:her\s+gunu?|hergun|every\s*day|each\s+day|daily|gunde\s+bir)'
    r'(?![a-z])',
    (m, lang) => _recurTok(m, Recur('DAILY')),
  ),
  Rule(
    r'\b(?:(?<w>her\s+hafta|haftada\s+bir|every\s+week|each\s+week|weekly|'
    r'once\s+a\s+week)|(?<mo>her\s+ay|ayda\s+bir|every\s+month|each\s+month|'
    r'monthly|once\s+a\s+month)|(?<y>her\s+yil|her\s+sene|yilda\s+bir|'
    r'senede\s+bir|every\s+year|each\s+year|yearly|annually|'
    r'once\s+a\s+year))(?![a-z])',
    (m, lang) => _recurTok(
      m,
      Recur(
        m.namedGroup('w') != null
            ? 'WEEKLY'
            : m.namedGroup('mo') != null
            ? 'MONTHLY'
            : 'YEARLY',
      ),
    ),
  ),

  // Süre: "yarım saat", "half an hour".
  Rule(r'\b(?:(?<in>in)\s+)?(?<w>yarim\s+saat|ceyrek\s+saat|half\s+an\s+hour|'
      r'half\s+hour|a\s+half\s+hour|quarter\s+of\s+an\s+hour|'
      r'an\s+hour\s+and\s+a\s+half|a\s+quarter\s+hour)(?:lik|luk|te|ta)?'
      r'(?<later>\s+sonra|\s+later|\s+from\s+now)?(?![a-z])', (m, lang) {
    final w = m.namedGroup('w')!;
    final minutes =
        w.contains('ceyrek') || w.contains('quarter')
            ? 15
            : w.contains('and a half')
            ? 90
            : 30;
    return _durationTok(m, minutes);
  }),
  // Süre: saat (+ dakika): "2 saat", "1,5 saat", "bir buçuk saat", "1h30m".
  Rule(
    r'(?<![\d.,:/])(?:\b(?<in>in)\s+)?(?:(?<n>\d{1,3}(?:[.,]\d{1,2})?)\s*|'
            r'\b(?<nw>' +
        numWordAlt +
        r')\s+)(?<buc>bucuk\s*)?(?:-\s*(?<n2>\d{1,3}(?:[.,]\d{1,2})?)\s*)?'
            r'(?:saat|sa|hours?|hrs?|h)(?:lik|luk|te|ta)?(?![a-z])'
            r'(?:\s*(?:ve\s+|and\s+)?(?<min>\d{1,2})\s*'
            r'(?:dakika|dak|dk|minutes?|mins?|min|m)(?:lik|luk)?(?![a-z]))?'
            r'(?<half>\s+and\s+a\s+half)?'
            r'(?<later>\s+sonra|\s+later|\s+from\s+now)?(?![a-z])',
    (m, lang) {
      final n =
          _decimal(m.namedGroup('n2')) ??
          _decimal(m.namedGroup('n')) ??
          numberOf(m.namedGroup('nw') ?? '')?.toDouble();
      if (n == null) return null;
      var hours = n;
      if (m.namedGroup('buc') != null || m.namedGroup('half') != null) {
        hours += 0.5;
      }
      final extra = int.tryParse(m.namedGroup('min') ?? '') ?? 0;
      return _durationTok(m, (hours * 60).round() + extra);
    },
  ),
  // Süre: dakika: "45 dk", "90 min", "on dakika", "45m".
  Rule(
    r'(?<![\d.,:/])(?:\b(?<in>in)\s+)?(?:(?<n>\d{1,3})\s*|\b(?<nw>' +
        numWordAlt +
        r')\s+)(?:dakika|dak|dk|minutes?|mins?|min|(?<=\d)m)'
            r'(?:lik|luk|da|de)?(?![a-z])'
            r'(?<later>\s+sonra|\s+later|\s+from\s+now)?(?![a-z])',
    (m, lang) {
      final n = numberOf(m.namedGroup('n') ?? m.namedGroup('nw')!);
      return n == null ? null : _durationTok(m, n);
    },
  ),

  // Göreli gün: "3 gün sonra", "in 3 days", "2 weeks later", "within 3 days".
  Rule(
    r'\b(?<n>\d{1,3}|' +
        trNumAlt +
        r')\s+(?<u>gun|hafta|ay|yil|sene)\s+sonra(?:ya|ki|si)?(?![a-z])',
    (m, lang) => _relativeTok(m),
  ),
  Rule(
    r'\b(?<w>in|within)\s+(?<n>\d{1,3}|' +
        enNumAlt +
        r')\s+(?<u>days?|weeks?|months?|years?)(?![a-z])',
    (m, lang) => _relativeTok(m)?..selfDeadline = m.namedGroup('w') == 'within',
  ),
  Rule(
    r'\b(?<n>\d{1,3}|' +
        enNumAlt +
        r')\s+(?<u>days?|weeks?|months?)\s+(?:later|from\s+now)(?![a-z])',
    (m, lang) => _relativeTok(m),
  ),

  // Mutlak tarih: ISO "2027-03-12".
  Rule(
    r"\b(?<y>\d{4})-(?<mo>\d{1,2})-(?<d>\d{1,2})(?!\d)" + _monSuf + _end,
    (m, lang) => _dateTok(
      m,
      int.parse(m.namedGroup('mo')!),
      int.parse(m.namedGroup('d')!),
      int.parse(m.namedGroup('y')!),
    ),
  ),
  // "12.03.2027", "12/03/27", "12-03-2027" (gün önce).
  Rule(
    r'(?<![\d.:/])(?<d>\d{1,2})(?<sep>[./-])(?<mo>\d{1,2})\k<sep>'
            r'(?<y>\d{4}|\d{2})(?!\d|[./]\d)' +
        _monSuf +
        _end,
    (m, lang) => _dateTok(
      m,
      int.parse(m.namedGroup('mo')!),
      int.parse(m.namedGroup('d')!),
      _year(m.namedGroup('y')),
    ),
  ),
  // "12 mart", "12 mart 2027", "12th of march", "1 ocak'ta".
  Rule(
    r'(?<![\d.:/])(?<d>\d{1,2})' +
        _ordSuf +
        r'\s*(?:of\s+)?(?<mo>' +
        monthAlt +
        r')\.?' +
        _monSuf +
        r"(?:\s*,?\s*(?<y>\d{4})(?:'?(?:de|da|te|ta))?)?" +
        _end,
    (m, lang) => _dateTok(
      m,
      monthOf(m.namedGroup('mo')!),
      int.parse(m.namedGroup('d')!),
      _year(m.namedGroup('y')),
    ),
  ),
  // "march 12", "mar 12th", "march 12, 2027".
  Rule(
    r'\b(?<mo>' +
        enMonthAlt +
        r')\.?\s+(?<d>\d{1,2})(?:st|nd|rd|th)?(?!\d|[.:/]\d)'
            r'(?:\s*,?\s*(?<y>\d{4}))?(?![a-z\d:])',
    (m, lang) => _dateTok(
      m,
      monthOf(m.namedGroup('mo')!),
      int.parse(m.namedGroup('d')!),
      _year(m.namedGroup('y')),
    ),
  ),

  // Saat aralığı: "14-16", "14:00–15:30 arası", "3-5pm", "saat 14-16".
  Rule(
    r'(?:\b(?:saat|from|between)\s+)?(?<![\d.:/,])' +
        _t('s') +
        r'\s*-\s*' +
        _t('e') +
        r'(?!\d|[.:/]\d)(?!\s*' +
        _units +
        r")(?:'?(?:ya|ye|a|e)\s+kadar|\s+arasi(?:nda)?)?" +
        _end,
    (m, lang) => _range(m, lang),
  ),
  Rule(
    r'\bfrom\s+' + _t('s') + r'\s+(?:to|till|until)\s+' + _t('e') + _end,
    (m, lang) => _range(m, lang),
  ),
  Rule(
    r'\bbetween\s+' + _t('s') + r'\s+and\s+' + _t('e') + _end,
    (m, lang) => _range(m, lang),
  ),
  Rule(
    r'(?:\bsaat\s+)?(?<![\d.:/,])' +
        _t('s') +
        r'\s+(?:ile|ila|ve)\s+' +
        _t('e') +
        r'\s+arasi(?:nda)?(?![a-z])',
    (m, lang) => _range(m, lang),
  ),
  Rule(
    r"(?:\bsaat\s+)?(?<![\d.:/,])" +
        _t('s') +
        r"'?(?:dan|den|tan|ten)\s+(?:saat\s+)?" +
        _t('e') +
        r"'?(?:ya|ye|a|e)(?:\s+kadar)?" +
        _end,
    (m, lang) => _range(m, lang),
  ),
  Rule(
    r'(?<![\d.:/,])' + _t('s') + r'\s+(?:to|till|until)\s+' + _t('e') + _end,
    (m, lang) => _range(m, lang, strong: true),
  ),

  // Gün dilimi + saat: "akşam 8'de", "sabah 9", "öğleden sonra 3", "gece 11".
  Rule(
    r"\b(?:(?<this>bu|this)\s+)?(?<dp>" +
        dayPartAlt +
        r")(?:'?(?:leyin|i))?\s+(?:(?:saat|at)\s+)?(?<![\d.:/])" +
        _t('') +
        r'(?!\d|[.:/]\d)' +
        _numSuf +
        _approx +
        _end,
    _dayPartTime,
  ),
  // "8 in the evening", "11 at night".
  Rule(r'(?:\bat\s+)?(?<![\d.:/])(?<h>\d{1,2})(?:[:.](?<m>\d{2}))?\s+'
      r'(?:in\s+the\s+(?<dp>morning|afternoon|evening)|at\s+(?<dp2>night|noon))'
      r'(?![a-z])', (m, lang) {
    final dp = dayPartOf(m.namedGroup('dp') ?? m.namedGroup('dp2')!);
    final h = int.parse(m.namedGroup('h')!);
    final mi = int.tryParse(m.namedGroup('m') ?? '') ?? 0;
    if (h > 23 || mi > 59) return null;
    return _tok(m, SpanKind.time)
      ..time = RawTime(h, minute: mi, literal: h == 0 || h >= 13, dayPart: dp)
      ..dayPart = dp;
  }),
  // "15:30", "at 9:30 pm", "15:30'da".
  Rule(
    r'(?:\b(?<pre>saat|at|around|about|approx)\s+|@\s*)?(?<![\d.:/])'
            r'(?<h>\d{1,2}):(?<m>\d{2})(?![\d:])(?:\s*(?<p>[ap])\.?m\b\.?)?' +
        _numSuf +
        _approx +
        _end,
    _clock,
  ),
  // "saat 3", "saat 9da", "at 9", "@9", "saat 15.30'da".
  Rule(
    r'(?:\b(?<pre>saat|at|around|about)\s+|@\s*)(?<h>\d{1,2})'
            r'(?:\.(?<m>\d{2}))?(?![\d:/]|[.,]\d)(?:\s*(?<p>[ap])\.?m\b\.?)?' +
        _numSuf +
        _approx +
        _end,
    _clock,
  ),
  // "3pm", "3 pm", "10.30am".
  Rule(
    r'(?:\b(?<pre>at|around|about)\s+)?(?<![\d.:/])(?<h>\d{1,2})'
    r'(?:[.:](?<m>\d{2}))?\s*(?<p>[ap])\.?m\b\.?(?![a-z\d])',
    _clock,
  ),
  // Nokta çifti: "15.30" saat, "12.03" tarih; belirsizse sonra çözülür.
  Rule(
    r"(?:\b(?<pre>saat|at)\s+)?(?<![\d.:/,])(?<a>\d{1,2})\.(?<b>\d{2})"
            r"(?!\d|\.\d)(?:\s*(?<p>[ap])\.?m\b\.?)?"
            r"(?:'?(?:dan|den|tan|ten|da|de|ta|te|ya|ye|a|e|si|i))?" +
        _end,
    (m, lang) {
      final a = int.parse(m.namedGroup('a')!);
      final b = int.parse(m.namedGroup('b')!);
      final mer = m.namedGroup('p');
      final forcedTime = m.namedGroup('pre') != null || mer != null;
      final timeOk = b <= 59 && (mer != null ? a >= 1 && a <= 12 : a <= 23);
      final dateOk = !forcedTime && a >= 1 && a <= 31 && b >= 1 && b <= 12;
      if (!timeOk && !dateOk) return null;
      if (timeOk && !dateOk) {
        final t = RawTime(
          a,
          minute: b,
          meridiem: mer,
          literal:
              mer == null &&
              (a == 0 || a >= 13 || m.namedGroup('a')!.startsWith('0')),
        );
        final tok = _tok(m, SpanKind.time)..time = t;
        if (m.namedGroup('pre') == 'at' && lang == Lang.tr) {
          tok.start = m.start + m[0]!.indexOf(_firstDigit);
        }
        return tok;
      }
      if (dateOk && !timeOk) return _dateTok(m, b, a, null);
      return _tok(m, SpanKind.time)
        ..ambiguousDot = true
        ..dotA = a
        ..dotB = b;
    },
  ),
  // "12/03".
  Rule(
    r'(?<![\d/.])(?<d>\d{1,2})/(?<mo>\d{1,2})(?![\d/])' + _monSuf + _end,
    (m, lang) => _dateTok(
      m,
      int.parse(m.namedGroup('mo')!),
      int.parse(m.namedGroup('d')!),
      null,
    ),
  ),
  // "15'te", "3'te", "9da"; "5'e kadar".
  Rule(r"(?<![\d.:/,])(?<h>\d{1,2})'?(?:da|de|ta|te)(?![a-z\d])" + _approx, (
    m,
    lang,
  ) {
    final hs = m.namedGroup('h')!;
    if (int.parse(hs) > 23) return null;
    return _tok(m, SpanKind.time)..time = _hourOnly(hs);
  }),
  Rule(r"(?<![\d.:/,])(?<h>\d{1,2})'?(?:ya|ye|a|e)(?=\s+kadar(?![a-z]))", (
    m,
    lang,
  ) {
    final hs = m.namedGroup('h')!;
    if (int.parse(hs) > 23) return null;
    return _tok(m, SpanKind.time)..time = _hourOnly(hs);
  }),

  // Gün adı: "cuma", "cumaya", "cuma günü", "bu cuma", "haftaya cuma",
  // "next friday", "friday next week".
  Rule(
    r'\b(?:(?<mod>gelecek\s+hafta(?:ki)?|onumuzdeki\s+hafta(?:ki)?|'
            r"next\s+week(?:'s)?|haftaya|gelecek|onumuzdeki|next|coming|bu|"
            r'this)\s+)?(?:(?<wd>' +
        wdFullAlt +
        r')' +
        _wdSuf +
        r'(?:\s+gun(?:u|une|unde|unden|e)?)?|(?<ab>' +
        wdAbbrAlt +
        '|' +
        wdTrShortAlt +
        r')\.?)(?:\s+(?<nw>next\s+week))?(?![a-z])',
    _weekday,
  ),
  // Hafta sonu, ay sonu.
  Rule(r'\b(?:(?<mod>bu|this|haftaya|gelecek|onumuzdeki|next)\s+)?'
      r"(?:hafta\s?sonu|weekend)(?:'?(?:nda|ndan|na|nu|ya|e|a))?(?![a-z])", (
    m,
    lang,
  ) {
    final mod = m.namedGroup('mod');
    final next = mod != null && mod != 'bu' && mod != 'this';
    return _tok(m, SpanKind.date)..date = WeekendDate(nextWeek: next);
  }),
  Rule(
    r'\b(?:bu\s+|this\s+)?(?:ay\s?sonu|end\s+of\s+(?:the\s+)?month|'
    r"month\s+end)(?:'?(?:nda|ndan|na|nu))?(?![a-z])",
    (m, lang) => _tok(m, SpanKind.date)..date = const MonthEndDate(),
  ),
  // Göreli günler: bugün, yarın, öbür gün, tomorrow...
  Rule(r'\b(?<w>yarindan\s+sonra|(?:the\s+)?day\s+after\s+tomorrow|obur\s+gun|'
      r'haftaya\s+bugun|a\s+week\s+from\s+today|bugun|today|tonight|yarin|'
      r"tomorrow|tmrw|tmr)(?:'?(?:ndan|nden|dan|den|nki|ki|ku|ne|ya|ye|e|a|u|"
      r'de|da))?(?![a-z])', (m, lang) {
    final w = m.namedGroup('w')!;
    final int days;
    if (w.startsWith('yarindan') ||
        w.contains('after') ||
        w.startsWith('obur')) {
      days = 2;
    } else if (w.contains('hafta') || w.contains('week')) {
      days = 7;
    } else if (w == 'bugun' || w == 'today' || w == 'tonight') {
      days = 0;
    } else {
      days = 1;
    }
    final tok = _tok(m, SpanKind.date)..date = RelativeDays(days);
    if (w == 'tonight') tok.dayPart = DayPart.evening;
    return tok;
  }),
  // "haftaya", "gelecek hafta", "next week", "next month".
  Rule(r'\b(?<w>gelecek\s+hafta|onumuzdeki\s+hafta|next\s+week|haftaya|'
      r"gelecek\s+ay|onumuzdeki\s+ay|next\s+month)(?:'?(?:ya|ye|a|e|ki|da|de|"
      r'ta|te|nin))?(?![a-z])', (m, lang) {
    final w = m.namedGroup('w')!;
    final month = w.endsWith('ay') || w.endsWith('month');
    return _tok(m, SpanKind.date)
      ..date =
          month
              ? const NextMonthDate()
              : const WeekdayDate(DateTime.monday, WeekdayMode.nextWeek);
  }),
  // Tek başına gün dilimi: "akşam", "yarın sabah", "bu akşam", "tonight".
  Rule(
    r'\b(?:(?<this>bu|this)\s+)?(?<dp>' +
        dayPartAlt +
        r")(?:'?(?:leyin|yin|ndan|dan|den|tan|ten|nda|si|ya|ye|i|a|e|da|de))?(?![a-z])",
    (m, lang) {
      final word = m.namedGroup('dp')!;
      final dp = dayPartOf(word);
      if (dp == null) return null;
      final tok = _tok(m, SpanKind.time)..dayPart = dp;
      if (m.namedGroup('this') != null || word == 'tonight') {
        tok.date = const RelativeDays(0);
      }
      return tok;
    },
  ),
  // "ayın 15'i", "the 15th".
  Rule(
    r"\b(?:bu\s+)?ayin\s+(?<d>\d{1,2})'?"
    r'(?:sinde|sunde|inde|unde|nde|sine|sune|ine|une|si|su|i|u)?(?![a-z\d])',
    (m, lang) => _dayOfMonth(m),
  ),
  Rule(
    r'\b(?:on\s+)?the\s+(?<d>\d{1,2})(?:st|nd|rd|th)(?![a-z])',
    (m, lang) => _dayOfMonth(m),
  ),

  // Öncelik.
  Rule(
    r'\b(?:(?<p3>cok\s+onemli|cok\s+acil|acilen|acil|very\s+important|urgent|'
    r'asap|high\s+priority|top\s+priority|yuksek\s+oncelik(?:li)?|'
    r'priority\s+high)|(?<p2>onemli|important|oncelikli|'
    r'orta\s+oncelik(?:li)?|medium\s+priority|priority\s+medium)|'
    r'(?<p1>dusuk\s+oncelik(?:li)?|low\s+priority|priority\s+low))(?![a-z])',
    (m, lang) => _tok(m, SpanKind.priority)
      ..priority =
          m.namedGroup('p3') != null
              ? 3
              : m.namedGroup('p2') != null
              ? 2
              : 1,
  ),
  Rule(r'!+', (m, lang) {
    final n = m.end - m.start;
    return _tok(m, SpanKind.priority)..priority = n > 3 ? 3 : n;
  }),
];

Tok? _relativeTok(RegExpMatch m) {
  final n = numberOf(m.namedGroup('n')!);
  if (n == null) return null;
  final u = m.namedGroup('u')!;
  final DateSpec spec;
  if (u.startsWith('gun') || u.startsWith('day')) {
    spec = RelativeDays(n);
  } else if (u.startsWith('hafta') || u.startsWith('week')) {
    spec = RelativeDays(7 * n);
  } else if (u.startsWith('ay') || u.startsWith('month')) {
    spec = RelativeMonths(n);
  } else {
    spec = RelativeMonths(12 * n);
  }
  return _tok(m, SpanKind.date)..date = spec;
}

Tok? _dayOfMonth(RegExpMatch m) {
  final d = int.parse(m.namedGroup('d')!);
  if (d < 1 || d > 31) return null;
  return _tok(m, SpanKind.date)..date = DayOfMonthDate(d);
}

/// Gün belirten parçadan hemen sonra gelen çıplak sayı: "yarın 15 toplantı".
final RegExp bareHourAfterDay = RegExp(
  r"\s+(?:saat\s+)?(?<h>\d{1,2})(?![\d.:/',])(?!\s*" + _units + r')(?![a-z])',
);
