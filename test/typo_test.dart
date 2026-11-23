import 'package:test/test.dart';
import 'package:nl_task_parser/nl_task_parser.dart';

/// Yazım yanlışı telafisi: gün/ay/göreli gün adına çok yakın kelimeler
/// düzeltilir; gerçek kelimelere dokunulmaz.
void main() {
  const x = RuleExtractor();
  final now = DateTime(2026, 10, 24, 11); // Cumartesi

  ExtractedTask one(String s) => x.parse(s, now: now).tasks.single;

  group('düzeltilir', () {
    for (final (input, start, title) in [
      ('yrın 15te dişçi', DateTime(2026, 10, 25, 15), 'dişçi'),
      ('yarn 15te dişçi', DateTime(2026, 10, 25, 15), 'dişçi'),
      ('perşmbe 14:00 lab', DateTime(2026, 10, 29, 14), 'lab'),
      ('çarşmba 13:00 tarih', DateTime(2026, 10, 28, 13), 'tarih'),
      ('pazartsi 9:00 fizik', DateTime(2026, 10, 26, 9), 'fizik'),
      ('perşmbeye kadar rapor', null, 'rapor'),
      ('15 ekmi sınav', null, 'sınav'),
      ('12 kasm toplantı', null, 'toplantı'),
      ('tomorow 3pm dentist', DateTime(2026, 10, 25, 15), 'dentist'),
      ('wendesday 10am standup', DateTime(2026, 10, 28, 10), 'standup'),
      ('fridy 5pm drinks', DateTime(2026, 10, 30, 17), 'drinks'),
      // Atlanan harfler
      ('arın 15te dişçi', DateTime(2026, 10, 25, 15), 'dişçi'),
      ('ugün 18de spor', DateTime(2026, 10, 24, 18), 'spor'),
      ('prşmbe 14:00 lab', DateTime(2026, 10, 29, 14), 'lab'),
      ('crşmba 13:00 tarih', DateTime(2026, 10, 28, 13), 'tarih'),
      ('pzrtesi 9:00 fizik', DateTime(2026, 10, 26, 9), 'fizik'),
      ('akşm 7de sinema', DateTime(2026, 10, 24, 19), 'sinema'),
      ('yarın15te dişçi', DateTime(2026, 10, 25, 15), 'dişçi'),
      ('saat15 diş', DateTime(2026, 10, 24, 15), 'diş'),
      ('slı 18:00 spor', DateTime(2026, 10, 27, 18), 'spor'),
      ('cma 10:00 kahve', DateTime(2026, 10, 30, 10), 'kahve'),
    ]) {
      test(input, () {
        final t = one(input);
        expect(t.title, title);
        if (start != null) expect(t.start, start);
        expect(t.spans.any((s) => s.corrected), isTrue);
        expect(t.confidence, lessThanOrEqualTo(0.75));
      });
    }

    test('15 ekmi → 15 Ekim', () {
      final t = one('15 ekmi sınav');
      final d = t.start ?? t.deadline;
      expect(d?.month, 10);
      expect(d?.day, 15);
    });

    test('düzeltilen aralık özgün kelimenin üstünde', () {
      const s = 'yrın 15te dişçi';
      final t = one(s);
      final c = t.spans.firstWhere((p) => p.corrected);
      expect(s.substring(c.start, c.end), 'yrın');
    });
  });

  group('dokunulmaz', () {
    for (final input in [
      "Mert'le kahve",
      'Mert 15te gelecek',
      'pazarlık yap',
      'kasa defteri',
      'car wash 10am',
      'cama bak',
      'ekmek al',
      'gene toplantı 15:00',
      'sınav kağıdı',
      'money transfer 3pm',
      'yarım ekmek al',
      'aksan çalış 15:00',
      'match 3pm',
      'mark 5 kitap',
      'azar 5 dk',
      'eşim 5te gelir',
      'ekip 3te toplantı',
      'lab3 rapor',
      'kimya101 notları',
      'ama 5te çık',
      'bir 3 saat',
      'her slı spor',
      'top 5 film',
      'cumartesi sabah 10 maç',
      'saat 9 maç',
    ]) {
      test(input, () {
        final t = one(input);
        expect(t.spans.where((s) => s.corrected), isEmpty, reason: '$t');
      });
    }

    test('doğru yazım aynı kalır', () {
      final t = one('yarın 15te diş hekimi');
      expect(t.spans.any((s) => s.corrected), isFalse);
      expect(t.confidence, greaterThan(0.9));
    });
  });
}
