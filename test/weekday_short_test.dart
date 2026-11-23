import 'package:test/test.dart';
import 'package:nl_task_parser/nl_task_parser.dart';

/// Ders programı kısaltmaları (Sal, Çar, Per, Cum, Paz) yalnızca ardından
/// saat gelince gün sayılır; İngilizce "car", "per" bozulmaz.
void main() {
  final x = RuleExtractor();
  final now = DateTime(2026, 10, 24, 11); // Cumartesi

  Future<({String title, DateTime? start})> run(String s) async {
    final t = (await x.extract(s, now: now)).tasks.single;
    return (title: t.title, start: t.start);
  }

  for (final (input, weekday, title) in [
    ('Sal 10:00 Kimya', DateTime.tuesday, 'Kimya'),
    ('Çar 13:00 Tarih', DateTime.wednesday, 'Tarih'),
    ('Per. 08:30 Matematik', DateTime.thursday, 'Matematik'),
    ('Cum 14:00 Edebiyat', DateTime.friday, 'Edebiyat'),
    ('Paz 11:00 Koşu', DateTime.sunday, 'Koşu'),
  ]) {
    test(input, () async {
      final r = await run(input);
      expect(r.start?.weekday, weekday);
      expect(r.title, title);
    });
  }

  test('car wash 10am: car gün değil', () async {
    final r = await run('car wash 10am');
    expect(r.title, 'car wash');
    expect(r.start, DateTime(2026, 10, 25, 10));
  });

  test('5 per hour: per gün değil', () async {
    final r = await run('pay 5 per hour');
    expect(r.title.contains('per'), isTrue);
  });
}
