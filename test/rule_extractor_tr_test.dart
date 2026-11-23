import 'package:test/test.dart';
import 'package:nl_task_parser/nl_task_parser.dart';

import 'parser_test_utils.dart';

// now = Cuma 23 Ekim 2026 10:00. Bu hafta: 19–25 Ekim, gelecek: 26 Ekim–1 Kasım.

void main() {
  group('TR göreli günler', () {
    runCases([
      Case(
        'bugün market',
        title: 'market',
        start: dt(2026, 10, 23),
        allDay: true,
      ),
      Case(
        'bugün 15:00 toplantı',
        title: 'toplantı',
        start: dt(2026, 10, 23, 15),
        allDay: false,
      ),
      Case(
        "yarın 15'te diş hekimi",
        title: 'diş hekimi',
        start: dt(2026, 10, 24, 15),
      ),
      Case(
        'yarına kadar ödev',
        title: 'ödev',
        start: null,
        deadline: dt(2026, 10, 24, 23, 59),
      ),
      Case('öbür gün berber', title: 'berber', start: dt(2026, 10, 25)),
      Case('obur gun berber', title: 'berber', start: dt(2026, 10, 25)),
      Case('yarından sonra sınav', title: 'sınav', start: dt(2026, 10, 25)),
      Case(
        '3 gün sonra fatura öde',
        title: 'fatura öde',
        start: dt(2026, 10, 26),
      ),
      Case('iki hafta sonra kontrol', title: 'kontrol', start: dt(2026, 11, 6)),
      Case(
        '2 ay sonra diş kontrolü',
        title: 'diş kontrolü',
        start: dt(2026, 12, 23),
      ),
      Case(
        'haftaya toplantı',
        title: 'toplantı',
        start: dt(2026, 10, 26),
        allDay: true,
      ),
      Case('gelecek hafta bütçe', title: 'bütçe', start: dt(2026, 10, 26)),
      Case('haftaya cuma sunum', title: 'sunum', start: dt(2026, 10, 30)),
      Case('haftaya bugün kahve', title: 'kahve', start: dt(2026, 10, 30)),
      Case('gelecek pazartesi rapor', title: 'rapor', start: dt(2026, 10, 26)),
      Case(
        'önümüzdeki salı seminer',
        title: 'seminer',
        start: dt(2026, 10, 27),
      ),
      Case(
        'gelecek hafta çarşamba sunum',
        title: 'sunum',
        start: dt(2026, 10, 28),
      ),
      Case('bu cuma parti', title: 'parti', start: dt(2026, 10, 23)),
      Case('bu pazar piknik', title: 'piknik', start: dt(2026, 10, 25)),
      Case('hafta sonu sinema', title: 'sinema', start: dt(2026, 10, 24)),
      Case('gelecek ay vize', title: 'vize', start: dt(2026, 11, 1)),
      Case(
        'ay sonuna kadar fatura',
        title: 'fatura',
        start: null,
        deadline: dt(2026, 10, 31, 23, 59),
      ),
    ]);
  });

  group('TR gün adları', () {
    runCases([
      Case(
        'salıya sunum',
        title: 'sunum',
        start: dt(2026, 10, 27),
        allDay: true,
      ),
      Case('sali kuaför', title: 'kuaför', start: dt(2026, 10, 27)),
      Case('carsamba spor', title: 'spor', start: dt(2026, 10, 28)),
      Case('persembe 10:00 lab', title: 'lab', start: dt(2026, 10, 29, 10)),
      Case(
        "Perşembe'ye kadar ödev",
        title: 'ödev',
        start: null,
        deadline: dt(2026, 10, 29, 23, 59),
      ),
      Case(
        'pazartesiye kadar başvuru',
        title: 'başvuru',
        deadline: dt(2026, 10, 26, 23, 59),
      ),
      Case(
        "cuma günü saat 3'te toplantı",
        title: 'toplantı',
        start: dt(2026, 10, 23, 15),
      ),
      // Bugün cuma, saat yok → gelecek cuma.
      Case('cuma toplantı', title: 'toplantı', start: dt(2026, 10, 30)),
      // Bugün cuma ama 09:00 geçti → gelecek cuma.
      Case("cuma 9'da kahvaltı", title: 'kahvaltı', start: dt(2026, 10, 30, 9)),
      Case('Cumartesi yüzme', title: 'yüzme', start: dt(2026, 10, 24)),
      Case('PAZAR kahvaltı', title: 'kahvaltı', start: dt(2026, 10, 25)),
      Case(
        'pazar günü aile yemeği',
        title: 'aile yemeği',
        start: dt(2026, 10, 25),
      ),
      Case('cuma akşamı parti', title: 'parti', start: dt(2026, 10, 23, 19)),
      Case('cumartesi sabah 10 maç', title: 'maç', start: dt(2026, 10, 24, 10)),
    ]);
  });

  group('TR mutlak tarihler', () {
    runCases([
      Case(
        '12 mart doğum günü',
        title: 'doğum günü',
        start: dt(2027, 3, 12),
        allDay: true,
      ),
      Case('12 mart 2027 düğün', title: 'düğün', start: dt(2027, 3, 12)),
      Case(
        'fizik finali 12 ocak 09.30',
        title: 'fizik finali',
        start: dt(2027, 1, 12, 9, 30),
        allDay: false,
      ),
      Case('5 kasım vize', title: 'vize', start: dt(2026, 11, 5)),
      Case("1 ocak'ta tatil", title: 'tatil', start: dt(2027, 1, 1)),
      Case('30 ekim sunum', title: 'sunum', start: dt(2026, 10, 30)),
      Case('23 ekim rapor', title: 'rapor', start: dt(2026, 10, 23)),
      // Bu yıl geçti → gelecek yıl.
      Case('22 ekim rapor', title: 'rapor', start: dt(2027, 10, 22)),
      Case('12.03 sınav', title: 'sınav', start: dt(2027, 3, 12)),
      Case('12.03.2027 vize', title: 'vize', start: dt(2027, 3, 12)),
      Case('05.11.26 seminer', title: 'seminer', start: dt(2026, 11, 5)),
      Case('12/03 randevu', title: 'randevu', start: dt(2027, 3, 12)),
      Case('2027-03-12 tatil', title: 'tatil', start: dt(2027, 3, 12)),
      Case(
        "15 mart'a kadar başvuru",
        title: 'başvuru',
        deadline: dt(2027, 3, 15, 23, 59),
      ),
      Case(
        'fizik vizesi 5 kasım saat 13.30',
        title: 'fizik vizesi',
        start: dt(2026, 11, 5, 13, 30),
      ),
      Case('29 şubat', start: dt(2028, 2, 29)),
    ]);
  });

  group('TR saatler', () {
    runCases([
      Case('15:30 kahve', title: 'kahve', start: dt(2026, 10, 23, 15, 30)),
      Case("15.30'da kahve", title: 'kahve', start: dt(2026, 10, 23, 15, 30)),
      Case("15:30'da kahve", title: 'kahve', start: dt(2026, 10, 23, 15, 30)),
      Case('saat 3 toplantı', title: 'toplantı', start: dt(2026, 10, 23, 15)),
      // 09:00 geçti → yarın.
      Case('saat 9da ders', title: 'ders', start: dt(2026, 10, 24, 9)),
      Case(
        "3'te veli toplantısı",
        title: 'veli toplantısı',
        start: dt(2026, 10, 23, 15),
      ),
      Case("11'de toplantı", title: 'toplantı', start: dt(2026, 10, 23, 11)),
      Case("akşam 8'de yemek", title: 'yemek', start: dt(2026, 10, 23, 20)),
      Case('sabah 9 koşu', title: 'koşu', start: dt(2026, 10, 24, 9)),
      Case('öğlen yemek', title: 'yemek', start: dt(2026, 10, 23, 12)),
      Case('öğle yemeği', title: 'yemeği', start: dt(2026, 10, 23, 12)),
      Case(
        'öğleden sonra 3 doktor',
        title: 'doktor',
        start: dt(2026, 10, 23, 15),
      ),
      Case('gece 11 film', title: 'film', start: dt(2026, 10, 23, 23)),
      Case('yarın akşam sinema', title: 'sinema', start: dt(2026, 10, 24, 19)),
      Case(
        'annemi ara akşam',
        title: 'annemi ara',
        start: dt(2026, 10, 23, 19),
      ),
      Case('yarın sabah 7 uçuş', title: 'uçuş', start: dt(2026, 10, 24, 7)),
      Case("akşam saat 9'da maç", title: 'maç', start: dt(2026, 10, 23, 21)),
      Case(
        "bu akşam 8'de konser",
        title: 'konser',
        start: dt(2026, 10, 23, 20),
      ),
      Case('15:00 gibi kahve', title: 'kahve', start: dt(2026, 10, 23, 15)),
      Case(
        "saat 5'e kadar başvuru",
        title: 'başvuru',
        start: null,
        deadline: dt(2026, 10, 23, 17),
      ),
      Case(
        'akşama kadar bitir',
        title: 'bitir',
        deadline: dt(2026, 10, 23, 19),
      ),
      Case('yarın 15 toplantı', title: 'toplantı', start: dt(2026, 10, 24, 15)),
      Case('cuma 10.10 sunum', title: 'sunum', start: dt(2026, 10, 23, 10, 10)),
      Case('yarın 09:30 03:00 değil', start: dt(2026, 10, 24, 9, 30)),
    ]);
  });

  group('TR aralıklar', () {
    runCases([
      Case(
        'cuma 14-16 kimya lab',
        title: 'kimya lab',
        start: dt(2026, 10, 23, 14),
        end: dt(2026, 10, 23, 16),
        duration: const Duration(hours: 2),
      ),
      Case(
        '14:00-15:30 toplantı',
        title: 'toplantı',
        start: dt(2026, 10, 23, 14),
        end: dt(2026, 10, 23, 15, 30),
      ),
      Case(
        '14.00–15.30 arası seminer',
        title: 'seminer',
        start: dt(2026, 10, 23, 14),
        end: dt(2026, 10, 23, 15, 30),
      ),
      Case(
        'saat 10-12 ders',
        title: 'ders',
        start: dt(2026, 10, 24, 10),
        end: dt(2026, 10, 24, 12),
      ),
      Case(
        "14'ten 16'ya kadar nöbet",
        title: 'nöbet',
        start: dt(2026, 10, 23, 14),
        end: dt(2026, 10, 23, 16),
        deadline: null,
      ),
      Case(
        '10 ile 12 arası ders',
        title: 'ders',
        start: dt(2026, 10, 24, 10),
        end: dt(2026, 10, 24, 12),
      ),
      Case(
        'yarın 9-17 staj',
        title: 'staj',
        start: dt(2026, 10, 24, 9),
        end: dt(2026, 10, 24, 17),
      ),
      Case(
        'akşam 8-10 arası parti',
        title: 'parti',
        start: dt(2026, 10, 23, 20),
        end: dt(2026, 10, 23, 22),
      ),
      Case(
        '2-4 arası etüt',
        title: 'etüt',
        start: dt(2026, 10, 23, 14),
        end: dt(2026, 10, 23, 16),
      ),
      Case(
        'gece 23-01 nöbet',
        start: dt(2026, 10, 23, 23),
        end: dt(2026, 10, 24, 1),
      ),
    ]);
  });

  group('TR süreler', () {
    runCases([
      Case(
        "toplantı 2 saat yarın 10'da",
        title: 'toplantı',
        start: dt(2026, 10, 24, 10),
        duration: const Duration(hours: 2),
        end: dt(2026, 10, 24, 12),
        estimate: null,
      ),
      Case(
        '45 dk yürüyüş',
        title: 'yürüyüş',
        start: null,
        duration: null,
        estimate: const Duration(minutes: 45),
      ),
      Case(
        '45 dakika kitap',
        title: 'kitap',
        estimate: const Duration(minutes: 45),
      ),
      Case(
        '1,5 saat okuma',
        title: 'okuma',
        estimate: const Duration(minutes: 90),
      ),
      Case(
        'yarım saat meditasyon',
        title: 'meditasyon',
        estimate: const Duration(minutes: 30),
      ),
      Case(
        'bir buçuk saat ders çalış',
        title: 'ders çalış',
        estimate: const Duration(minutes: 90),
      ),
      Case(
        '1 saat 30 dakika antrenman',
        title: 'antrenman',
        estimate: const Duration(minutes: 90),
      ),
      Case(
        'yarın 14:00 2 saatlik sınav',
        title: 'sınav',
        start: dt(2026, 10, 24, 14),
        duration: const Duration(hours: 2),
      ),
      // Tarih var saat yok → süre tahmin olur.
      Case(
        'yarın 2 saat kitap',
        start: dt(2026, 10, 24),
        allDay: true,
        duration: null,
        estimate: const Duration(hours: 2),
      ),
      Case(
        'tez taslağı 6 saat cumaya kadar !!',
        title: 'tez taslağı',
        start: null,
        estimate: const Duration(hours: 6),
        deadline: dt(2026, 10, 30, 23, 59),
        priority: 2,
      ),
      Case(
        'rapor yaz 3 saat cumaya kadar',
        title: 'rapor yaz',
        start: null,
        estimate: const Duration(hours: 3),
        deadline: dt(2026, 10, 30, 23, 59),
      ),
      Case(
        '15 dakika sonra çay',
        title: 'çay',
        start: dt(2026, 10, 23, 10, 15),
        allDay: false,
      ),
      Case('2 saat sonra ilaç', title: 'ilaç', start: dt(2026, 10, 23, 12)),
    ]);
  });

  group('TR tekrar', () {
    runCases([
      Case(
        'her gün su iç',
        title: 'su iç',
        rrule: 'FREQ=DAILY',
        start: dt(2026, 10, 23),
        allDay: true,
      ),
      Case(
        'her salı spor',
        title: 'spor',
        rrule: 'FREQ=WEEKLY;BYDAY=TU',
        start: dt(2026, 10, 27),
      ),
      Case(
        'her salı ve perşembe 18:00 spor',
        title: 'spor',
        rrule: 'FREQ=WEEKLY;BYDAY=TU,TH',
        start: dt(2026, 10, 27, 18),
      ),
      Case(
        'her pazartesi, çarşamba ve cuma 08:30 ders',
        title: 'ders',
        rrule: 'FREQ=WEEKLY;BYDAY=MO,WE,FR',
        start: dt(2026, 10, 26, 8, 30),
      ),
      Case(
        'salıları yüzme',
        title: 'yüzme',
        rrule: 'FREQ=WEEKLY;BYDAY=TU',
        start: dt(2026, 10, 27),
      ),
      Case(
        "hafta içi her gün 7'de kalk",
        title: 'kalk',
        rrule: 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR',
        start: dt(2026, 10, 26, 7),
      ),
      Case(
        'hafta sonları kahvaltı',
        title: 'kahvaltı',
        rrule: 'FREQ=WEEKLY;BYDAY=SA,SU',
        start: dt(2026, 10, 24),
      ),
      Case(
        'her hafta temizlik',
        title: 'temizlik',
        rrule: 'FREQ=WEEKLY',
        start: dt(2026, 10, 23),
      ),
      Case(
        'her hafta cuma 17:00 rapor',
        title: 'rapor',
        rrule: 'FREQ=WEEKLY;BYDAY=FR',
        start: dt(2026, 10, 23, 17),
      ),
      Case('her ay kira', title: 'kira', rrule: 'FREQ=MONTHLY'),
      Case(
        "her ayın 15'i kira öde",
        title: 'kira öde',
        rrule: 'FREQ=MONTHLY;BYMONTHDAY=15',
        start: dt(2026, 11, 15),
      ),
      Case(
        'her ayın son günü rapor',
        title: 'rapor',
        rrule: 'FREQ=MONTHLY;BYMONTHDAY=-1',
        start: dt(2026, 10, 31),
      ),
      Case(
        'iki haftada bir pazartesi toplantı',
        title: 'toplantı',
        rrule: 'FREQ=WEEKLY;INTERVAL=2;BYDAY=MO',
        start: dt(2026, 10, 26),
      ),
      Case(
        "her sabah 7'de koşu",
        title: 'koşu',
        rrule: 'FREQ=DAILY',
        start: dt(2026, 10, 24, 7),
      ),
      Case(
        "akşamları 8'de yürüyüş",
        title: 'yürüyüş',
        rrule: 'FREQ=DAILY',
        start: dt(2026, 10, 23, 20),
      ),
      Case('gün aşırı koşu', title: 'koşu', rrule: 'FREQ=DAILY;INTERVAL=2'),
      Case(
        '3 günde bir sulama',
        title: 'sulama',
        rrule: 'FREQ=DAILY;INTERVAL=3',
      ),
      Case(
        'her yıl 12 mart doğum günü',
        title: 'doğum günü',
        rrule: 'FREQ=YEARLY',
        start: dt(2027, 3, 12),
      ),
    ]);
  });

  group('TR öncelik', () {
    runCases([
      Case('acil fatura öde', title: 'fatura öde', priority: 3),
      Case(
        'çok önemli vergi beyannamesi',
        title: 'vergi beyannamesi',
        priority: 3,
      ),
      Case('önemli müşteri ara', title: 'müşteri ara', priority: 2),
      Case('fatura öde !', title: 'fatura öde', priority: 1),
      Case('fatura öde !!!', title: 'fatura öde', priority: 3),
      Case('ödev!!', title: 'ödev', priority: 2),
      Case(
        'düşük öncelikli dolap düzenle',
        title: 'dolap düzenle',
        priority: 1,
      ),
      Case('kitap oku', title: 'kitap oku', priority: 0, start: null),
    ]);
  });

  group('TR alt görevler', () {
    runCases([
      Case(
        'market: süt, ekmek, yumurta',
        title: 'market',
        subtasks: ['süt', 'ekmek', 'yumurta'],
      ),
      Case(
        'yarın market: süt, ekmek ve yumurta',
        title: 'market',
        start: dt(2026, 10, 24),
        subtasks: ['süt', 'ekmek', 'yumurta'],
      ),
      Case('Not: tek öğe', subtasks: const <String>[]),
    ]);
  });

  group('TR başlık temizliği', () {
    runCases([
      Case("toplantı saat 15:00'te", title: 'toplantı'),
      Case("çöpü at 9'da", title: 'çöpü at', start: dt(2026, 10, 24, 9)),
      Case('arabayı sat yarın', title: 'arabayı sat', start: dt(2026, 10, 24)),
      Case('- yarın 10:00 sunum', title: 'sunum', start: dt(2026, 10, 24, 10)),
      Case('Proje Toplantısı yarın 14:00', title: 'Proje Toplantısı'),
      Case('yarın, 15:00, ekip toplantısı', title: 'ekip toplantısı'),
      Case("İzmir'e git yarın", title: "İzmir'e git", start: dt(2026, 10, 24)),
      Case('kimya ödevi (yarın)', title: 'kimya ödevi'),
    ]);
  });

  group('TR aralık konumları', () {
    test('yarın 15te', () {
      expect(spansOf("yarın 15'te diş hekimi"), [
        ('yarın', SpanKind.date),
        ("15'te", SpanKind.time),
      ]);
    });
    test('tekrar + saat', () {
      expect(spansOf('her salı ve perşembe 18:00 spor'), [
        ('her salı ve perşembe', SpanKind.recurrence),
        ('18:00', SpanKind.time),
      ]);
    });
    test('süre + son tarih + öncelik', () {
      expect(spansOf('tez taslağı 6 saat cumaya kadar !!'), [
        ('6 saat', SpanKind.duration),
        ('cumaya kadar', SpanKind.deadline),
        ('!!', SpanKind.priority),
      ]);
    });
    test('kesmeli gün adı', () {
      expect(spansOf("Perşembe'ye kadar ödev"), [
        ("Perşembe'ye kadar", SpanKind.deadline),
      ]);
    });
    test('Türkçe büyük harf konumları kaydırmaz', () {
      expect(spansOf('İŞ GÖRÜŞMESİ ÇARŞAMBA 14:00'), [
        ('ÇARŞAMBA', SpanKind.date),
        ('14:00', SpanKind.time),
      ]);
    });
    test('aralık tek parça', () {
      expect(spansOf('14.00–15.30 arası seminer'), [
        ('14.00–15.30 arası', SpanKind.time),
      ]);
    });
  });

  group('TR güven', () {
    test('temiz > düz yapılacak > tanınmamış tarih > boş başlık', () {
      final clean = one("yarın 15'te diş hekimi").confidence;
      final plain = one('kitap oku').confidence;
      final missed = one('toplantı 25:00').confidence;
      final empty = one("yarın 3'te").confidence;
      expect(clean, greaterThan(plain));
      expect(plain, greaterThan(missed));
      expect(clean, greaterThanOrEqualTo(0.9));
      expect(missed, lessThan(0.5));
      expect(empty, lessThanOrEqualTo(0.4));
    });
    test('çelişen tarihler düşük güven', () {
      expect(one('yarın cuma toplantı').confidence, lessThan(0.6));
    });
    test('çıplak sayı saat sayıldıysa güven biraz düşer', () {
      expect(
        one('yarın 15 toplantı').confidence,
        lessThan(one("yarın 15'te toplantı").confidence),
      );
    });
    test('geçersiz tarih tanınmaz, güven düşer', () {
      final t = one('31 şubat sınav');
      expect(t.start, isNull);
      expect(t.confidence, lessThan(0.5));
    });
    test('başlıkta kalan rakam güveni düşürür', () {
      expect(
        one('Fizik 101 ödevi yarın').confidence,
        lessThan(one('Fizik ödevi yarın').confidence),
      );
    });
  });
}
