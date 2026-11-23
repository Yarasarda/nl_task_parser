import 'dart:math' as math;
import 'dart:typed_data';

import 'model.dart';
import 'date_rules.dart';
import 'fold.dart';
import 'lexicon.dart';
import 'rules.dart';
import 'title_cleaner.dart';
import 'tokens.dart';

final RegExp _bullet = RegExp(r'\s*(?:[-*•·–]|\d{1,2}[.)]|\[\s?[x ]?\])\s+');
final RegExp _gap = RegExp(
  r'^(?:\s|,|\bsaat\b|\bat\b|\bon\b|\bthe\b|\bof\b|\bgunu\b|\bde\b|\bda\b)*$',
);
final RegExp _deadlineBefore = RegExp(
  r'(?<![a-z])(?<m>by|until|till|til|due(?:\s+(?:by|on|date))?|before|'
  r'deadline\s*:?|no\s+later\s+than|en\s+gec|en\s+son|son\s+gun\s*:?|'
  r'son\s+tarih(?:i)?\s*:?|son\s+teslim(?:\s+tarihi)?\s*:?|'
  r'teslim\s+tarihi\s*:?)\s*$',
);
final RegExp _kadar = RegExp(r'\s*kadar(?![a-z])');

class _Deadline {
  _Deadline(this.toks, this.start, this.end, this.before);
  final List<Tok> toks;
  final int start;
  final int end;
  final bool before;
}

/// Tek satırı göreve çevirir. [base]: satırın tüm girdideki başlangıcı.
ExtractedTask? parseLine(String line, int base, DateTime now) {
  if (line.trim().isEmpty) return null;
  var folded = foldForMatch(line);
  final mask = Uint8List(line.length);
  final bulletEnd = _bullet.matchAsPrefix(folded)?.end ?? 0;
  if (bulletEnd > 0) {
    folded = (' ' * bulletEnd) + folded.substring(bulletEnd);
    for (var i = 0; i < bulletEnd; i++) {
      mask[i] = 2;
    }
  }
  final lang = detectLang(line, folded);

  // 1) Kurallar sırayla; ilk gelen aralığı sahiplenir.
  final toks = <Tok>[];
  for (final rule in rules) {
    for (final m in rule.re.allMatches(folded)) {
      if (m.end == m.start || _taken(mask, m.start, m.end)) continue;
      final tok = rule.build(m, lang);
      if (tok == null) continue;
      toks.add(tok);
      _mark(mask, tok.start, tok.end);
    }
  }

  // 2) Gün parçasından sonra çıplak sayı: "yarın 15 toplantı" (zayıf).
  final extra = <Tok>[];
  for (final t in toks) {
    if (t.kind != SpanKind.date || t.date == null) continue;
    final m = bareHourAfterDay.matchAsPrefix(folded, t.end) as RegExpMatch?;
    if (m == null) continue;
    final hs = m.namedGroup('h')!;
    final h = int.parse(hs);
    final numStart = m.end - hs.length;
    if (h > 23 || _taken(mask, numStart, m.end)) continue;
    final literal = h == 0 || h >= 13 || (hs.length == 2 && hs[0] == '0');
    extra.add(
      Tok(
          t.end + (m[0]!.length - m[0]!.trimLeft().length),
          m.end,
          SpanKind.time,
        )
        ..time = RawTime(h, literal: literal)
        ..penalty = 0.15,
    );
  }
  for (final t in extra) {
    toks.add(t);
    _mark(mask, t.start, t.end);
  }
  toks.sort((a, b) => a.start.compareTo(b.start));

  // 3) Belirsiz nokta çiftleri: başka tarih varsa saat, yoksa tarih.
  var hasDate = toks.any((t) => t.date != null && !t.ambiguousDot);
  for (final t in toks) {
    if (!t.ambiguousDot) continue;
    if (hasDate) {
      t.time = RawTime(t.dotA, minute: t.dotB, literal: t.dotA >= 13);
    } else {
      t.kind = SpanKind.date;
      t.date = AbsoluteDate(t.dotB, t.dotA);
      t.penalty += 0.05;
      hasDate = true;
    }
  }

  // 4) Son tarih grupları: "cumaya kadar", "by friday 5pm".
  final deadlines = <_Deadline>[];
  final inDeadline = <Tok>{};
  final temporal = [
    for (final t in toks)
      if (t.isTemporal &&
          t.kind != SpanKind.recurrence &&
          t.kind != SpanKind.duration &&
          t.kind != SpanKind.priority)
        t,
  ];
  var g = 0;
  while (g < temporal.length) {
    final group = [temporal[g]];
    var k = g + 1;
    while (k < temporal.length &&
        _gap.hasMatch(folded.substring(group.last.end, temporal[k].start))) {
      group.add(temporal[k]);
      k++;
    }
    g = k;
    final gs = group.first.start;
    final ge = group.last.end;
    final before = _deadlineBefore.firstMatch(folded.substring(0, gs));
    final after = _kadar.matchAsPrefix(folded, ge);
    if (before == null && after == null && !group.any((t) => t.selfDeadline)) {
      continue;
    }
    final ds = before?.start ?? gs;
    final de = after?.end ?? ge;
    if (_taken(mask, ds, gs) || _taken(mask, ge, de)) continue;
    _mark(mask, ds, de);
    deadlines.add(
      _Deadline(group, ds, de, before?.namedGroup('m') == 'before'),
    );
    inDeadline.addAll(group);
  }

  // 5) Bileşim.
  final normal = [
    for (final t in toks)
      if (!inDeadline.contains(t)) t,
  ];
  var conflicts = 0;
  var penalty = 0.0;
  for (final t in toks) {
    penalty += t.penalty;
  }

  DayPart? context;
  for (final t in normal) {
    if (t.dayPart != null) {
      context = t.dayPart;
      break;
    }
  }

  // Saat.
  Tok? timeTok;
  for (final t in normal) {
    if (t.endTime != null) {
      timeTok = t;
      break;
    }
  }
  for (final t in normal) {
    if (timeTok != null) break;
    if (t.time != null) timeTok = t;
  }
  RawTime? startRaw = timeTok?.time;
  if (timeTok?.endTime != null) {
    startRaw = rangeStart(startRaw!, timeTok!.endTime!);
  }
  int? minutes = startRaw == null ? null : resolveMinutes(startRaw, context);
  if (minutes == null && context != null) minutes = context.defaultHour * 60;
  for (final t in normal) {
    if (t == timeTok || t.time == null) continue;
    if (resolveMinutes(t.time!, context) != minutes) conflicts++;
  }

  // Şu andan göreli an: "2 saat sonra".
  Tok? fromNowTok;
  for (final t in normal) {
    if (t.fromNow != null) {
      if (fromNowTok != null || timeTok != null) conflicts++;
      fromNowTok ??= t;
    }
  }

  // Tarih: mutlak tarih gün adına tercih edilir; tutarlıysa çatışma sayılmaz.
  final dateToks = [
    for (final t in normal)
      if (t.date != null) t,
  ];
  Tok? dateTok;
  for (final t in dateToks) {
    if (t.date is AbsoluteDate) {
      dateTok = t;
      break;
    }
  }
  dateTok ??= dateToks.isEmpty ? null : dateToks.first;
  DateTime? day;
  if (dateTok != null) {
    day = resolveDate(dateTok.date!, now, minutes);
    if (day == null) penalty += 0.3; // geçersiz tarih
    for (final t in dateToks) {
      if (t == dateTok || day == null) continue;
      final other = resolveDate(t.date!, now, minutes);
      final consistent =
          other == day ||
          (t.date is WeekdayDate &&
              (t.date as WeekdayDate).weekday == day.weekday);
      if (!consistent) conflicts++;
    }
  }

  // Tekrar.
  Recur? recur;
  for (final t in normal) {
    final r = t.recur;
    if (r == null) continue;
    if (recur == null) {
      recur = r;
    } else if (recur.freq == r.freq && r.byMonthDay == recur.byMonthDay) {
      recur.byDay.addAll(r.byDay);
      if (r.interval > recur.interval) recur.interval = r.interval;
    } else {
      conflicts++;
    }
  }
  if (recur != null &&
      recur.freq == 'WEEKLY' &&
      recur.byDay.isEmpty &&
      dateTok?.date is WeekdayDate) {
    recur.byDay.add((dateTok!.date as WeekdayDate).weekday);
  }

  // Başlangıç.
  DateTime? start;
  var allDay = false;
  if (fromNowTok != null && dateTok == null) {
    start = now.add(fromNowTok.fromNow!);
    final s = start;
    start = DateTime(s.year, s.month, s.day, s.hour, s.minute);
  } else {
    day ??=
        recur != null
            ? firstOccurrence(recur, now, minutes)
            : (minutes != null ? todayOrTomorrow(now, minutes) : null);
    if (day != null) {
      start = minutes == null ? day : at(day, minutes);
      allDay = minutes == null;
    }
  }

  // Bitiş, süre, tahmin.
  DateTime? end;
  Duration? duration;
  Duration? estimate;
  Duration? durationTok;
  for (final t in normal) {
    if (t.duration == null) continue;
    if (durationTok != null && durationTok != t.duration) conflicts++;
    durationTok ??= t.duration;
  }
  if (start != null && timeTok?.endTime != null && minutes != null) {
    final endMin = resolveEndMinutes(timeTok!.endTime!, minutes, context);
    var e = at(dateOnly(start), endMin);
    if (!e.isAfter(start)) e = at(plusDays(e, 1), endMin);
    end = e;
    duration = e.difference(start);
    if (durationTok != null) conflicts++;
  } else if (durationTok != null) {
    if (start != null && !allDay) {
      duration = durationTok;
      end = start.add(durationTok);
    } else {
      estimate = durationTok;
    }
  }

  // Son tarih.
  DateTime? deadline;
  if (deadlines.length > 1) conflicts += deadlines.length - 1;
  if (deadlines.isNotEmpty) deadline = _resolveDeadline(deadlines.first, now);

  // Öncelik.
  var priority = 0;
  for (final t in normal) {
    final p = t.priority;
    if (p != null && p > priority) priority = p;
  }

  // Başlık ve alt görevler.
  final remainder = joinRemainder(line, folded, mask, lang);
  var title = tidy(remainder);
  var subtasks = const <String>[];
  final split = splitSubtasks(remainder);
  if (split != null) {
    title = split.$1;
    subtasks = split.$2;
  }

  // Aralıklar.
  final spans = <ParsedSpan>[
    for (final t in normal) ParsedSpan(base + t.start, base + t.end, t.kind),
    for (final d in deadlines)
      ParsedSpan(base + d.start, base + d.end, SpanKind.deadline),
  ]..sort((a, b) => a.start.compareTo(b.start));

  final confidence = _confidence(
    recognised: toks.isNotEmpty,
    lineDateish: dateishRe.hasMatch(folded),
    structured: subtasks.isNotEmpty,
    titleDateish: dateishRe.hasMatch(foldForMatch(title)),
    titleEmpty: title.isEmpty && subtasks.isEmpty,
    conflicts: conflicts,
    penalty: penalty,
  );

  return ExtractedTask(
    title: title,
    start: start,
    end: end,
    allDay: allDay,
    duration: duration,
    estimate: estimate,
    deadline: deadline,
    recurrence: recur?.toRRule(),
    priority: priority,
    subtasks: subtasks,
    spans: spans,
    confidence: confidence,
  );
}

DateTime? _resolveDeadline(_Deadline d, DateTime now) {
  DayPart? part;
  RawTime? time;
  DateSpec? spec;
  for (final t in d.toks) {
    part ??= t.dayPart;
    time ??= t.endTime ?? t.time;
    spec ??= t.date;
  }
  int? minutes = time == null ? null : resolveMinutes(time, part);
  if (minutes == null && part != null) minutes = part.defaultHour * 60;
  DateTime? day;
  if (spec != null) {
    day = resolveDate(spec, now, minutes);
  } else if (minutes != null) {
    day = todayOrTomorrow(now, minutes);
  }
  if (day == null) return null;
  if (minutes == null) {
    return d.before
        ? at(plusDays(day, -1), 23 * 60 + 59)
        : at(day, 23 * 60 + 59);
  }
  final t = at(day, minutes);
  return d.before ? t.subtract(const Duration(minutes: 1)) : t;
}

/// Güven sezgisi (0..1):
/// * Tanınan parça var, başlık temiz: 0.95.
/// * Hiç parça yok, satır tarihe benzemiyor (düz yapılacak): 0.8; alt görev
///   listesi çıktıysa 0.9.
/// * Hiç parça yok ama rakam / gün-ay adı var: 0.35 (kural kaçırdı).
/// * Başlıkta tarih benzeri kalıntı (rakam, gün/ay adı): −0.25.
/// * Her çatışma (iki farklı tarih/saat, iki tekrar, aralık + süre): −0.4.
/// * Zayıf çıkarımlar (çıplak sayı saat sayıldı, "12.03" tarih sayıldı,
///   geçersiz tarih): kendi payı kadar.
/// * Başlık boşsa en fazla 0.4.
double _confidence({
  required bool recognised,
  required bool lineDateish,
  required bool structured,
  required bool titleDateish,
  required bool titleEmpty,
  required int conflicts,
  required double penalty,
}) {
  double c;
  if (!recognised) {
    c = lineDateish ? 0.35 : (structured ? 0.9 : 0.8);
  } else {
    c = 0.95;
    if (titleDateish) c -= 0.25;
  }
  c -= 0.4 * conflicts;
  c -= penalty;
  if (titleEmpty) c = math.min(c, 0.4);
  return c.clamp(0.05, 1.0).toDouble();
}

bool _taken(Uint8List mask, int s, int e) {
  for (var i = s; i < e; i++) {
    if (mask[i] != 0) return true;
  }
  return false;
}

void _mark(Uint8List mask, int s, int e) {
  for (var i = s; i < e; i++) {
    mask[i] = 1;
  }
}
