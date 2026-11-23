import 'package:test/test.dart';
import 'package:nl_task_parser/nl_task_parser.dart';

import 'parser_test_utils.dart';

void main() {
  group('geç akşam (Cuma 22:30)', () {
    final late = DateTime(2026, 10, 23, 22, 30);
    runCases([
      Case('akşam yürüyüş', start: dt(2026, 10, 24, 19), now: late),
      Case('15:00 kahve', start: dt(2026, 10, 24, 15), now: late),
      Case('23:30 film', start: dt(2026, 10, 23, 23, 30), now: late),
      // Açıkça bugün denmişse geçmiş saat de bugündür.
      Case('bugün 15:00 toplantı', start: dt(2026, 10, 23, 15), now: late),
      Case(
        'her gün 21:00 ilaç',
        start: dt(2026, 10, 24, 21),
        rrule: 'FREQ=DAILY',
        now: late,
      ),
      Case('cuma 23:00 parti', start: dt(2026, 10, 23, 23), now: late),
      Case('cuma 21:00 parti', start: dt(2026, 10, 30, 21), now: late),
      Case('gece 11 film', start: dt(2026, 10, 23, 23), now: late),
    ]);
  });

  group('yıl sonu (Perşembe 31 Aralık 15:00)', () {
    final eve = DateTime(2026, 12, 31, 15);
    runCases([
      Case('yarın tatil', start: dt(2027, 1, 1), now: eve),
      Case('5 ocak sınav', start: dt(2027, 1, 5), now: eve),
      Case('12.03 vize', start: dt(2027, 3, 12), now: eve),
      Case('31 aralık parti', start: dt(2026, 12, 31), now: eve),
      Case('haftaya toplantı', start: dt(2027, 1, 4), now: eve),
      Case('next friday review', start: dt(2027, 1, 1), now: eve),
      Case(
        "her ayın 15'i kira",
        start: dt(2027, 1, 15),
        rrule: 'FREQ=MONTHLY;BYMONTHDAY=15',
        now: eve,
      ),
      Case(
        'ay sonuna kadar rapor',
        deadline: dt(2026, 12, 31, 23, 59),
        now: eve,
      ),
      Case('3 gün sonra kontrol', start: dt(2027, 1, 3), now: eve),
      Case('gelecek ay plan', start: dt(2027, 1, 1), now: eve),
      Case(
        'new year party tonight 11pm',
        start: dt(2026, 12, 31, 23),
        now: eve,
      ),
    ]);
  });

  group('pazartesi (19 Ekim 09:00): next vs haftaya', () {
    final monday = DateTime(2026, 10, 19, 9);
    runCases([
      Case('next friday demo', start: dt(2026, 10, 23), now: monday),
      Case('gelecek cuma demo', start: dt(2026, 10, 23), now: monday),
      Case('haftaya cuma demo', start: dt(2026, 10, 30), now: monday),
      Case('next week friday demo', start: dt(2026, 10, 30), now: monday),
      Case('bu cuma demo', start: dt(2026, 10, 23), now: monday),
      Case('cuma demo', start: dt(2026, 10, 23), now: monday),
      Case(
        'pazartesi 10:00 toplantı',
        start: dt(2026, 10, 19, 10),
        now: monday,
      ),
      Case('pazartesi 08:00 toplantı', start: dt(2026, 10, 26, 8), now: monday),
      Case('hafta sonu piknik', start: dt(2026, 10, 24), now: monday),
      Case('next week planning', start: dt(2026, 10, 26), now: monday),
      Case(
        'her pazartesi 10:00 ekip',
        start: dt(2026, 10, 19, 10),
        rrule: 'FREQ=WEEKLY;BYDAY=MO',
        now: monday,
      ),
    ]);
  });

  group('pazar (25 Ekim 12:00)', () {
    final sunday = DateTime(2026, 10, 25, 12);
    runCases([
      Case('hafta sonu piknik', start: dt(2026, 10, 25), now: sunday),
      Case('haftaya pazartesi', start: dt(2026, 10, 26), now: sunday),
      Case('bu pazartesi', start: dt(2026, 10, 26), now: sunday),
    ]);
  });

  group('çok satır', () {
    test('her boş olmayan satır bir görev', () {
      final r = extractor.parse(
        "yarın 15'te diş hekimi\n\n  \ncuma 14-16 kimya lab\nmarket: süt, ekmek",
        now: fridayTen,
      );
      expect(r.tasks.map((t) => t.title), [
        'diş hekimi',
        'kimya lab',
        'market',
      ]);
      expect(r.tasks[2].subtasks, ['süt', 'ekmek']);
    });
    test('aralıklar tüm girdiye göre konumlanır', () {
      const input = 'kitap oku\nyarın 15:00 sunum';
      final r = extractor.parse(input, now: fridayTen);
      final spans = r.tasks[1].spans;
      expect(
        [for (final s in spans) input.substring(s.start, s.end)],
        ['yarın', '15:00'],
      );
    });
    test('CRLF satır sonu', () {
      final r = extractor.parse('a yarın\r\nb bugün', now: fridayTen);
      expect(r.tasks.map((t) => t.title), ['a', 'b']);
    });
    test('madde imli liste', () {
      final r = extractor.parse(
        '- süt al\n* yarın 9:30 koşu\n1. rapor',
        now: fridayTen,
      );
      expect(r.tasks.map((t) => t.title), ['süt al', 'koşu', 'rapor']);
    });
    test('sonuç güveni en düşük satırınki', () {
      final r = extractor.parse(
        "yarın 15'te diş\ntoplantı 25:00",
        now: fridayTen,
      );
      expect(r.confidence, r.tasks[1].confidence);
      expect(r.confidence, lessThan(0.5));
    });
  });

  group('sınır durumlar', () {
    test('boş girdi', () {
      final r = extractor.parse('   ', now: fridayTen);
      expect(r.tasks, isEmpty);
      expect(r.confidence, 1.0);
    });
    test('async extract aynı sonucu verir', () async {
      final r = await extractor.extract('dentist tomorrow 3pm', now: fridayTen);
      expect(r.tasks.single.start, dt(2026, 10, 24, 15));
    });
    test('karışık dil', () {
      final t = one('yarın 3pm meeting');
      expect(t.start, dt(2026, 10, 24, 15));
      expect(t.title, 'meeting');
    });
    test('Türkçe satırda "sat" gün sayılmaz', () {
      final t = one('eski bisikleti sat');
      expect(t.start, isNull);
      expect(t.title, 'eski bisikleti sat');
    });
    test('İngilizce satırda "sat" cumartesidir', () {
      expect(one('sat 10am tennis with Ben').start, dt(2026, 10, 24, 10));
    });
    test('"money" içindeki "mon" tanınmaz', () {
      expect(one('send money').start, isNull);
    });
    test('"pazarlama" pazar değildir', () {
      expect(one('pazarlama sunumu').start, isNull);
    });
    test('yazarken yarım kalan girdi patlamaz', () {
      for (final s in [
        'yar',
        "15'",
        '14-',
        'her ',
        'every ',
        'by ',
        '12.',
        '!',
      ]) {
        expect(
          () => extractor.parse(s, now: fridayTen),
          returnsNormally,
          reason: s,
        );
      }
    });
    test('öncelik en yükseği alınır', () {
      expect(one('acil! rapor').priority, 3);
    });
    test('süre ve aralık birlikteyse aralık kazanır', () {
      final t = one('14-16 2 saat ders');
      expect(t.end, dt(2026, 10, 23, 16));
      expect(t.confidence, lessThan(0.6));
    });
    test('tüm görev alanları tutarlı: allDay yalnızca saatsiz başlangıçta', () {
      expect(one('yarın kitap').allDay, isTrue);
      expect(one('yarın 10:00 kitap').allDay, isFalse);
      expect(one('kitap').allDay, isFalse);
    });
  });

  group('katlama', () {
    test('uzunluk korunur', () {
      const s = 'İŞ Çarşamba ÖĞLEN ığüşöç’–';
      final f = foldForMatch(s);
      expect(f.length, s.length);
      expect(f, "is carsamba oglen igusoc'-");
    });
  });

  group('hız', () {
    test('tuş başına ayrıştırma hızlı', () {
      const lines = [
        "yarın 15'te diş hekimi",
        'her salı ve perşembe 18:00 spor',
        'submit report by friday 5pm !',
        'tez taslağı 6 saat cumaya kadar !!',
        'market: süt, ekmek, yumurta',
      ];
      extractor.parse(lines.first, now: fridayTen); // ısınma
      final sw = Stopwatch()..start();
      for (var i = 0; i < 200; i++) {
        extractor.parse(lines[i % lines.length], now: fridayTen);
      }
      sw.stop();
      // Ortalama satır başına 5 ms'nin altında (gerçekte çok daha az).
      expect(sw.elapsedMilliseconds, lessThan(1000));
    });
  });

  group('ParsedSpan', () {
    test('eşitlik', () {
      expect(
        const ParsedSpan(0, 3, SpanKind.date),
        const ParsedSpan(0, 3, SpanKind.date),
      );
    });
  });
}
