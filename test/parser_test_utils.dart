import 'package:test/test.dart';
import 'package:nl_task_parser/nl_task_parser.dart';

const extractor = RuleExtractor();

/// Cuma, 23 Ekim 2026, 10:00.
final DateTime fridayTen = DateTime(2026, 10, 23, 10, 0);

DateTime dt(int y, int m, int d, [int h = 0, int min = 0]) =>
    DateTime(y, m, d, h, min);

ExtractedTask one(String input, {DateTime? now}) {
  final r = extractor.parse(input, now: now ?? fridayTen);
  expect(r.tasks, hasLength(1), reason: input);
  return r.tasks.single;
}

/// Tanınan parçaların metni ve türü: [("yarın", date), ("15'te", time)].
List<(String, SpanKind)> spansOf(String input, {DateTime? now}) {
  final t = one(input, now: now);
  return [for (final s in t.spans) (input.substring(s.start, s.end), s.kind)];
}

const _unset = Object();

/// Tablo tabanlı tek durum. Verilmeyen alanlar denetlenmez; `null` verilen
/// alan null olmalıdır.
class Case {
  const Case(
    this.input, {
    this.title = _unset,
    this.start = _unset,
    this.end = _unset,
    this.allDay = _unset,
    this.duration = _unset,
    this.estimate = _unset,
    this.deadline = _unset,
    this.rrule = _unset,
    this.priority = _unset,
    this.subtasks = _unset,
    this.now,
  });

  final String input;
  final Object? title;
  final Object? start;
  final Object? end;
  final Object? allDay;
  final Object? duration;
  final Object? estimate;
  final Object? deadline;
  final Object? rrule;
  final Object? priority;
  final Object? subtasks;
  final DateTime? now;

  void check() {
    final t = one(input, now: now);
    void field(String name, Object? want, Object? got) {
      if (identical(want, _unset)) return;
      expect(got, want, reason: '$name of "$input"\n$t');
    }

    field('title', title, t.title);
    field('start', start, t.start);
    field('end', end, t.end);
    field('allDay', allDay, t.allDay);
    field('duration', duration, t.duration);
    field('estimate', estimate, t.estimate);
    field('deadline', deadline, t.deadline);
    field('recurrence', rrule, t.recurrence);
    field('priority', priority, t.priority);
    field('subtasks', subtasks, t.subtasks);
  }
}

void runCases(List<Case> cases) {
  for (final c in cases) {
    test(c.input, c.check);
  }
}
