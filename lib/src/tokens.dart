import 'model.dart';

enum Lang { tr, en }

/// Gün dilimi ve tek başına yazıldığında varsayılan saati.
enum DayPart {
  morning(9),
  noon(12),
  afternoon(15),
  lateAfternoon(17),
  evening(19),
  night(22);

  const DayPart(this.defaultHour);
  final int defaultHour;
}

/// Henüz çözülmemiş saat: "3" öğleden sonra mı sabah mı, sonra karar verilir.
class RawTime {
  const RawTime(
    this.hour, {
    this.minute = 0,
    this.meridiem,
    this.literal = false,
    this.dayPart,
  });

  final int hour;
  final int minute;

  /// 'a' (am) ya da 'p' (pm).
  final String? meridiem;

  /// 24 saat biçimi kesin: 0, 13-23 ya da başında sıfır ("09:30").
  final bool literal;
  final DayPart? dayPart;

  RawTime withMeridiem(String m) =>
      RawTime(hour, minute: minute, meridiem: m, dayPart: dayPart);
}

sealed class DateSpec {
  const DateSpec();
}

final class AbsoluteDate extends DateSpec {
  const AbsoluteDate(this.month, this.day, [this.year]);
  final int month;
  final int day;
  final int? year;
}

final class RelativeDays extends DateSpec {
  const RelativeDays(this.days);
  final int days;
}

final class RelativeMonths extends DateSpec {
  const RelativeMonths(this.months);
  final int months;
}

enum WeekdayMode {
  /// "cuma": sıradaki cuma (bugün yalnızca saati henüz geçmediyse).
  bare,

  /// "bu cuma": bu haftanın (Pzt–Paz) cuması; geçtiyse sıradaki.
  thisWeek,

  /// "gelecek cuma" / "next friday": bugünden sonraki ilk cuma.
  nextStrict,

  /// "haftaya cuma" / "next week friday": gelecek haftanın cuması.
  nextWeek,
}

final class WeekdayDate extends DateSpec {
  const WeekdayDate(this.weekday, this.mode);
  final int weekday;
  final WeekdayMode mode;
}

final class WeekendDate extends DateSpec {
  const WeekendDate({this.nextWeek = false});
  final bool nextWeek;
}

final class MonthEndDate extends DateSpec {
  const MonthEndDate();
}

final class NextMonthDate extends DateSpec {
  const NextMonthDate();
}

final class DayOfMonthDate extends DateSpec {
  const DayOfMonthDate(this.day);
  final int day;
}

class Recur {
  Recur(this.freq, {this.interval = 1, List<int>? byDay, this.byMonthDay})
    : byDay = byDay ?? <int>[];

  final String freq; // DAILY | WEEKLY | MONTHLY | YEARLY
  int interval;
  final List<int> byDay; // DateTime.monday..sunday
  final int? byMonthDay; // -1 = ayın son günü

  static const _codes = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

  String toRRule() {
    final b = StringBuffer('FREQ=')..write(freq);
    if (interval > 1) b.write(';INTERVAL=$interval');
    if (byDay.isNotEmpty) {
      final days = byDay.toSet().toList()..sort();
      b.write(';BYDAY=');
      b.write(days.map((d) => _codes[d - 1]).join(','));
    }
    if (byMonthDay != null) b.write(';BYMONTHDAY=$byMonthDay');
    return b.toString();
  }
}

/// Bir kuralın tanıdığı parça. Konumlar satır içidir.
class Tok {
  Tok(this.start, this.end, this.kind);

  int start;
  int end;
  SpanKind kind;

  DateSpec? date;
  RawTime? time;
  RawTime? endTime;
  DayPart? dayPart;
  Duration? duration;

  /// "2 saat sonra" / "in 30 minutes": şu andan itibaren kesin an.
  Duration? fromNow;
  Recur? recur;
  int? priority;

  /// Güvenden düşülecek pay (zayıf çıkarım).
  double penalty = 0;

  /// "12.03" gibi tarih mi saat mi belli olmayan nokta çifti.
  bool ambiguousDot = false;
  int dotA = 0;
  int dotB = 0;

  /// "within 3 days": kendisi son tarih.
  bool selfDeadline = false;

  bool get isTemporal =>
      date != null || time != null || dayPart != null || fromNow != null;
}
