import 'tokens.dart';

// Tarih ve saat çözümleme kuralları. Belirsizlik kuralları:
//
// * Çıplak saat 1–6 (am/pm, gün dilimi, başta sıfır yoksa) öğleden sonradır
//   (13–18); 7–12 olduğu gibi kalır. "03:00" ve 13–23 kesindir.
// * Gün dilimi saati kaydırır: "akşam 8" → 20, "gece 11" → 23, "gece 2" → 02
//   (aynı gün), "öğlen 1" → 13, "sabah 6" → 06.
// * Tarihsiz saat: bugün henüz geçmediyse bugün, geçtiyse yarın.
// * Çıplak gün adı ("cuma"): sıradaki o gün. Bugün o günse yalnızca saat
//   verilmiş ve henüz geçmemişse bugün; aksi halde gelecek hafta.
// * "bu cuma": bu haftanın (Pzt–Paz) cuması, geçtiyse sıradaki.
// * "gelecek/önümüzdeki cuma", "next friday": bugünden sonraki ilk cuma.
// * "haftaya cuma", "next week friday": gelecek haftanın cuması.
// * "haftaya" / "gelecek hafta" / "next week" tek başına: gelecek pazartesi
//   (haftanın başı). "haftaya bugün": +7 gün.
// * Yılsız tarih bu yıl geçtiyse gelecek yıla kayar. Sayısal tarihler gün
//   önce okunur ("12.03" = 12 Mart).
// * "hafta sonu" / "weekend": bu cumartesi (hafta sonundaysak bugün).

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime plusDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

int daysInMonth(int y, int m) => DateTime(y, m + 1, 0).day;

DateTime at(DateTime day, int minutes) =>
    DateTime(day.year, day.month, day.day, minutes ~/ 60, minutes % 60);

DateTime? validDate(int y, int m, int d) {
  if (m < 1 || m > 12 || d < 1 || d > daysInMonth(y, m)) return null;
  return DateTime(y, m, d);
}

/// Gün dilimi ve am/pm bağlamıyla saati 0–23'e çevirir.
int resolveHour(RawTime t, DayPart? context) {
  final h = t.hour;
  final m = t.meridiem;
  if (m != null) return m == 'p' ? (h % 12) + 12 : h % 12;
  if (t.literal) return h;
  final dp = t.dayPart ?? context;
  if (dp != null) {
    switch (dp) {
      case DayPart.morning:
        return h;
      case DayPart.noon:
        return h <= 6 ? h + 12 : h;
      case DayPart.afternoon:
      case DayPart.lateAfternoon:
      case DayPart.evening:
        return h < 12 ? h + 12 : h;
      case DayPart.night:
        if (h >= 7 && h <= 11) return h + 12;
        return h == 12 ? 0 : h;
    }
  }
  return (h >= 1 && h <= 6) ? h + 12 : h;
}

int resolveMinutes(RawTime t, DayPart? context) =>
    resolveHour(t, context) * 60 + t.minute;

/// Aralık bitişi: başlangıçtan sonraki ilk anlamlı saat ("2-4" → 14–16,
/// "11-1" → 11–13). Hiçbiri sonra değilse ertesi güne taşar.
int resolveEndMinutes(RawTime e, int startMinutes, DayPart? context) {
  if (e.meridiem != null || e.literal) return resolveMinutes(e, context);
  final first = e.hour * 60 + e.minute;
  if (first > startMinutes) return first;
  if (e.hour < 12) {
    final second = (e.hour + 12) * 60 + e.minute;
    if (second > startMinutes) return second;
  }
  return first;
}

/// Aralık başı: yalnızca bitişte am/pm varsa onu devralır ("3-5pm").
RawTime rangeStart(RawTime s, RawTime e) {
  if (s.meridiem != null || s.literal || e.meridiem == null) return s;
  final same = s.withMeridiem(e.meridiem!);
  if (resolveMinutes(same, null) < resolveMinutes(e, null)) return same;
  return s.withMeridiem(e.meridiem == 'p' ? 'a' : 'p');
}

bool _ahead(DateTime day, int? minutes, DateTime now) =>
    minutes != null && at(day, minutes).isAfter(now);

DateTime todayOrTomorrow(DateTime now, int minutes) {
  final today = dateOnly(now);
  return _ahead(today, minutes, now) ? today : plusDays(today, 1);
}

DateTime _mondayOf(DateTime d) => plusDays(d, -(d.weekday - 1));

/// Tarih tarifini güne çevirir; geçersizse null ("31 şubat").
DateTime? resolveDate(DateSpec spec, DateTime now, int? minutes) {
  final today = dateOnly(now);
  switch (spec) {
    case RelativeDays(:final days):
      return plusDays(today, days);
    case RelativeMonths(:final months):
      final y = today.year;
      final m = today.month + months;
      final last = DateTime(y, m + 1, 0).day;
      return DateTime(y, m, today.day > last ? last : today.day);
    case WeekdayDate(:final weekday, :final mode):
      switch (mode) {
        case WeekdayMode.bare:
          var diff = (weekday - today.weekday) % 7;
          if (diff == 0 && !_ahead(today, minutes, now)) diff = 7;
          return plusDays(today, diff);
        case WeekdayMode.thisWeek:
          final d = plusDays(_mondayOf(today), weekday - 1);
          return d.isBefore(today) ? plusDays(d, 7) : d;
        case WeekdayMode.nextStrict:
          var diff = (weekday - today.weekday) % 7;
          if (diff == 0) diff = 7;
          return plusDays(today, diff);
        case WeekdayMode.nextWeek:
          return plusDays(_mondayOf(today), 7 + weekday - 1);
      }
    case WeekendDate(:final nextWeek):
      if (nextWeek) return plusDays(_mondayOf(today), 12);
      if (today.weekday >= DateTime.saturday) return today;
      return plusDays(today, DateTime.saturday - today.weekday);
    case MonthEndDate():
      return DateTime(today.year, today.month + 1, 0);
    case NextMonthDate():
      return DateTime(today.year, today.month + 1, 1);
    case DayOfMonthDate(:final day):
      for (var i = 0; i < 13; i++) {
        final y = today.year;
        final m = today.month + i;
        final d = validDate(DateTime(y, m).year, DateTime(y, m).month, day);
        if (d != null && !d.isBefore(today)) return d;
      }
      return null;
    case AbsoluteDate(:final month, :final day, :final year):
      if (year != null) return validDate(year, month, day);
      for (var y = today.year; y < today.year + 8; y++) {
        final d = validDate(y, month, day);
        if (d != null && !d.isBefore(today)) return d;
      }
      return null;
  }
}

bool _matches(Recur r, DateTime d) {
  if (r.byDay.isNotEmpty && !r.byDay.contains(d.weekday)) return false;
  final md = r.byMonthDay;
  if (md != null) {
    final want = md == -1 ? daysInMonth(d.year, d.month) : md;
    if (d.day != want) return false;
  }
  return true;
}

/// Tekrarın ilk oluşumu: bugünden itibaren kurala uyan ilk gün; bugün,
/// saati verilmiş ve geçmişse atlanır.
DateTime firstOccurrence(Recur r, DateTime now, int? minutes) {
  final today = dateOnly(now);
  for (var i = 0; i < 400; i++) {
    final d = plusDays(today, i);
    if (i == 0 && minutes != null && !_ahead(d, minutes, now)) continue;
    if (_matches(r, d)) return d;
  }
  return today;
}
