import 'package:nl_task_parser/nl_task_parser.dart';

void main() {
  const parser = RuleExtractor();
  // Fixed reference time so the output is reproducible: Fri 23 Oct 2026 10:00.
  final now = DateTime(2026, 10, 23, 10);

  const inputs = [
    "yarın 15'te diş hekimi 45 dk",
    'her salı 19:00 spor',
    'cumaya kadar rapor 3 saat !!',
    'pazartesi 14-16 toplantı: sunum, bütçe',
    'yrın 9da kahvaltı',
    'tomorrow 3pm call with Ali',
    'every friday 7pm gym',
    'finish thesis by monday',
  ];

  for (final input in inputs) {
    final task = parser.parse(input, now: now).tasks.single;
    print('"$input"');
    print('  title:      ${task.title}');
    if (task.start != null) print('  start:      ${task.start}');
    if (task.end != null) print('  end:        ${task.end}');
    if (task.allDay) print('  allDay:     true');
    if (task.duration != null) print('  duration:   ${task.duration}');
    if (task.estimate != null) print('  estimate:   ${task.estimate}');
    if (task.deadline != null) print('  deadline:   ${task.deadline}');
    if (task.recurrence != null) print('  recurrence: ${task.recurrence}');
    if (task.priority > 0) print('  priority:   ${task.priority}');
    if (task.subtasks.isNotEmpty) print('  subtasks:   ${task.subtasks}');
    final spans = [
      for (final s in task.spans)
        '${input.substring(s.start, s.end)}=${s.kind.name}'
            '${s.corrected ? '*' : ''}',
    ];
    print('  spans:      $spans');
    print('  confidence: ${task.confidence.toStringAsFixed(2)}');
  }
}
